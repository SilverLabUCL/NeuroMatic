#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2017 Jason Rothman
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
//	Contact Jason@ThinkRandom.com
//	www.NeuroMatic.ThinkRandom.com
//
//****************************************************************
//****************************************************************
//
//	NeuroMatic Clamp tab for data acquisition
//
//	Created in the Laboratory of Dr. Angus Silver
//	NPP Department, UCL, London
//
//	This work was supported by the Medical Research Council
//	"Grid Enabled Modeling Tools and Databases for NeuroInformatics"
//
//	Began 1 July 2003
//
//****************************************************************
//****************************************************************

Function NMNotesEditHeader()

	String ndf = NMNotesDF
	String name = StrVarOrDefault(ndf+"H_Name", "")
	String lab = StrVarOrDefault(ndf+"H_Lab", "")
	String title = StrVarOrDefault(ndf+"H_Title", "")
	
	Prompt name, "enter user name:"
	Prompt lab, "enter user lab/affiliation:"
	Prompt title, "experiment title:"
	DoPrompt "Edit User Name and Lab", name, lab, title
	
	if (V_flag == 1)
		return -1 // cancel
	endif
	
	SetNMstr(ndf+"H_Name", name)
	SetNMstr(ndf+"H_Lab", lab)
	SetNMstr(ndf+"H_Title", title)

End // NMNotesEditHeader

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesBasicUpdate()

	String cdf = NMClampDF, ndf = NMNotesDF
	
	SetNMstr(ndf+"F_Folder", GetDataFolder(0))
	SetNMstr(ndf+"F_Stim", StimCurrent())
	SetNMstr(ndf+"F_Tbgn", StrVarOrDefault("FileTime", ""))
	SetNMstr(ndf+"F_Tend", StrVarOrDefault("FileFinish", ""))
	//SetNMstr(ndf+"F_ExtFile", StrVarOrDefault("CurrentFile", "")) // does not work
	
End // NMNotesBasicUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampNotesCheck() // auto run via NM Package function

	Variable icnt
	String olist, ndf = NMNotesDF
	
	if (DataFolderExists(ndf) == 0)
		return -1
	endif
	
	SetNMstr(ndf+"FileType", "NMNotes")
	
	// header notes "H_"
	
	olist = NMNotesBasicList("H", 1)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		CheckNMstr(ndf+StringFromList(icnt, olist), "")
	endfor
	
	olist = NMNotesBasicList("H", 0)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		CheckNMvar(ndf+StringFromList(icnt, olist), Nan)
	endfor
	
	// file notes "F_"
	
	olist = NMNotesBasicList("F", 1)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		CheckNMstr(ndf+StringFromList(icnt, olist), "")
	endfor
	
	olist = NMNotesBasicList("F", 0)
	
	for (icnt = 0; icnt < ItemsInList(olist); icnt += 1)
		CheckNMvar(ndf+StringFromList(icnt, olist), Nan)
	endfor
	
	return 0

End // NMClampNotesCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampNotesConfigs() // auto run via NM Package function

	String fname = "ClampNotes"

	//
	// Header Notes: use name prefix "H_"
	// File Notes: use name prefix "F_"
	// Create your own by copying and pasting
	//
	
	// Header Strings:
	
	NMConfigStr(fname, "H_Name", "Your Name", "your name", "" )
	NMConfigStr(fname, "H_Lab", "Your Lab/Address", "your lab/address", "" )
	NMConfigStr(fname, "H_Title", "Experiment Title", "experiment title", "" )
		
	// Header Variables:
	
	//NMConfigVar(fname, "H_Age", Nan, "Age")
	
	// File Variables:
	
	NMConfigVar(fname, "F_Temp", Nan, "temperature", "C" )
	NMConfigVar(fname, "F_Relectrode", Nan, "electrode access resistance", "MOhms" )
	NMConfigVar(fname, "F_Cm", Nan, "cell capacitance", "pF" )
	
	// File Strings:
	
	//NMConfigStr(fname, "F_Drug", "", "Experimental drugs")

End // NMClampNotesConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMClampNotesVarType( df, varName )
	String df
	String varName
				
	NVAR /Z varH = $df + varName
	
	if ( NVAR_Exists( varH ) )
		return "N"
	endif
	
	SVAR /Z strH = $df + varName
		
	if ( SVAR_Exists( strH ) )
		return "S"
	endif
	
	return ""

End // NMClampNotesVarType

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesTable2Vars() // save table values to note vars

	String cdf = NMClampDF, ndf = NMNotesDF
	
	Variable icnt, objNum, type, nitem, sitem
	String objName, objStr
	
	String nlist = NMNotesVarList(ndf, "H_", "numeric") + NMNotesVarList(ndf, "F_", "numeric")
	String slist = NMNotesVarList(ndf, "H_", "string") + NMNotesVarList(ndf, "F_", "string")
	
	nlist = RemoveFromList(NMNotesBasicList("F",0), nlist, ";")
	slist = RemoveFromList(NMNotesBasicList("F",1), slist, ";")
	
	String tName = NMNotesTableName

	if (WinType(tName) != 2)
		return 0 // table doesnt exist
	endif
	
	if (WaveExists($cdf+"VarName") == 0)
		return 0 // waves dont exist
	endif
	
	Wave /T VarName = $(cdf+"VarName")
	Wave /T StrValue = $(cdf+"StrValue")
	Wave NumValue = $(cdf+"NumValue")
	
	for (icnt = 0; icnt < numpnts(VarName); icnt += 1)
	
		objName = VarName[icnt]
		
		if (strlen(objName) == 0)
			continue
		endif
		
		if (StringMatch(objName, "Header Notes:") == 1)
			continue
		endif
		
		if (StringMatch(objName, "File Notes:") == 1)
			continue
		endif
		
		objName = NMNotesCheckVarName(objName)
		
		if ( icnt < numpnts( NumValue ) )
			objNum = NumValue[ icnt ]
		else
			objNum = NaN
		endif
		
		if ( icnt < numpnts( StrValue ) )
			objStr = StrValue[ icnt ]
		else
			objStr = ""
		endif
		
		type = 0 // undefined
		
		nitem = WhichListItem(objName, nlist, ";", 0, 0)
		sitem = WhichListItem(objName, slist, ";", 0, 0)
		
		if (nitem >= 0) // numeric variable
			type = 1
			nlist = RemoveListItem(nitem, nlist)
			objNum = NMNotesCheckNumValue(objName, objStr, objNum)
		elseif (sitem >= 0) // string variable
			type = 2
			slist = RemoveListItem(sitem, slist)
			objStr = NMNotesCheckStrValue(objName, objStr, objNum)
		endif

		if (type == 0)
			if (strlen(objStr) > 0)
				type = 2
				objStr = NMNotesCheckStrValue(objName, objStr, objNum)
			else
				type = 1
			endif
		endif
		
		KillStrings /Z $(ndf+objName)
		KillVariables /Z $(ndf+objName)
		
		if (type == 1)
			SetNMvar(ndf+objName, objNum)
		elseif (type == 2)
			SetNMstr(ndf+objName, objStr)
		endif
		
	endfor
	
	// kill deleted variables
	
	NMNotesKillVar(ndf, nlist, 0)
	NMNotesKillStr(ndf, slist, 0)
	
End // NMNotesTable2Vars

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesCheckNumValue(varName, strValue, numValue)
	String varName, strValue
	Variable numValue
	
	if ((strlen(strValue) > 0) && (StringMatch(strValue, NMNotesStr) == 0))
	
		if (numtype(numValue) > 0)
			numValue = str2num(strValue)
		endif
		
		Prompt numValue, varName
		DoPrompt "Please Check Numeric Input Value", numValue
		
		if (V_flag == 1)
			numValue = Nan // cancel
		endif
		
	endif
	
	return numValue

End // NMNotesCheckNumValue

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNotesCheckStrValue(varName, strValue, numValue)
	String varName, strValue
	Variable numValue
	
	if (numtype(numValue) == 0)
	
		if (strlen(strValue) == 0)
			strValue += num2str(numValue)
		else
			strValue += " : " + num2str(numValue)
		endif
		
		Prompt strValue, varName
		DoPrompt "Please Check String Input Value", strValue
		
		if (V_flag == 1)
			strValue = "" // cancel
		endif
		
	endif
	
	return strValue

End // NMNotesCheckStrValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesAddPrompt( df, typeHFP )
	String df
	String typeHFP // "H" for Header, "F" for File, "P" for Progress popup item
	
	String title, varName = "", varName2, typeNS = "numeric"
	Variable askValue = 1, numValue = NaN
	String strValue = "", typeExists, pslist
	
	strswitch( typeHFP )
		case "H": // heade
			title = "NM Clamp Notes : Add Header Parameter"
			typeNS = "text"
			break
		case "F": // file
			title = "NM Clamp Notes : Add File Parameter"
			typeNS = "numeric"
			askValue = 0 // file values are set manually
			break
		case "P": // acq progress popup
			title = "NM Clamp Notes : Add Progress Popup Item"
			typeNS = "text"
			pslist = NMNotesVarList( df, "P_", "string" )
	endswitch
	
	Prompt varName "enter parameter name:"
	Prompt typeNS "select parameter type:", popup "numeric;text;"
	Prompt numValue "enter parameter value:"
	Prompt strValue "enter parameter text:"
	
	if ( StringMatch( typeHFP, "P" ) )
	
		varName = "Item" + num2istr( ItemsInList( pslist ) )
		
	else
	
		DoPrompt title, varName, typeNS
		
		if (V_flag == 1)
			return 0 // cancel
		endif
	
	endif
	
	varName2 = typeHFP + "_" + varName
	
	varName2 = ReplaceString( "H_H_", varName2, "H_" )
	varName2 = ReplaceString( "F_F_", varName2, "F_" )
	varName2 = ReplaceString( "P_P_", varName2, "P_" )
	
	typeExists = NMClampNotesVarType( df, varName2 )
	
	strswitch( typeExists )
		case "N":
			DoAlert /T=title 0, NMQuotes( varName ) + " already exists as a numerica parameter"
			return -1
		case "S":
			DoAlert /T=title 0, NMQuotes( varName ) + " already exists as a text parameter"
			return -1
	endswitch
	
	if ( askValue )
		if ( StringMatch( typeNS, "numeric" ) )
			DoPrompt title, numValue
		else
			DoPrompt title, strValue
		endif
	endif
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	if ( StringMatch( typeNS, "numeric" ) )
		return NMNotesVarAdd( df, varName, typeHFP, value = numValue )
	endif
	
	if ( StringMatch( typeNS, "text" ) )
		return NMNotesStrAdd( df, varName, typeHFP, strValue = strValue )
	endif
	
End // NMNotesAddPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesVarAdd( df, varName, typeHFP [ value ] )
	String df
	String varName
	String typeHFP // "H" for Header, "F" for File, "P" for Progress popup item
	Variable value
	
	String typeExists, varName2
	
	if ( ParamIsDefault( value ) )
		value = NaN
	endif
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	varName2 = typeHFP + "_" + varName
	
	varName2 = ReplaceString( "H_H_", varName2, "H_" )
	varName2 = ReplaceString( "F_F_", varName2, "F_" )
	varName2 = ReplaceString( "P_P_", varName2, "P_" )
	
	typeExists = NMClampNotesVarType( df, varName2 )
	
	if ( strlen( typeExists ) == 1 )
		return -1 // aleady exists
	endif
	
	SetNMvar( df + varName2, value )
	
	return 0
	
End // NMNotesVarAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesStrAdd( df, varName, typeHFP [ strValue ] )
	String df
	String varName
	String typeHFP // "H" for Header, "F" for File, "P" for Progress popup item
	String strValue
	
	String typeExists, varName2
	
	if ( ParamIsDefault( strValue ) )
		strValue = ""
	endif
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	varName2 = typeHFP + "_" + varName
	
	varName2 = ReplaceString( "H_H_", varName2, "H_" )
	varName2 = ReplaceString( "F_F_", varName2, "F_" )
	varName2 = ReplaceString( "P_P_", varName2, "P_" )
	
	typeExists = NMClampNotesVarType( df, varName2 )
	
	if ( strlen( typeExists ) == 1 )
		return -1 // aleady exists
	endif
	
	SetNMstr( df + varName2, strValue )
	
	return 0
	
End // NMNotesStrAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesKillVar(df, vlist, ask)
	String df, vlist
	Variable ask
	
	Variable icnt, kill = 2
	String objName
	
	for (icnt = 0; icnt < ItemsInList(vlist); icnt += 1) // kill unused variables
	
		objName = StringFromList(icnt, vlist)
		
		if (ask == 1)
			Prompt kill, "kill variable " + NMQuotes( objName ) + "?", popup "no;yes;"
			DoPrompt "Encountered Unused Note Variable", kill
		endif
		
		if (kill == 2)
			KillVariables $(df+objName)
		endif
		
	endfor
	
End // NMNotesKillVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesKillStr(df, vlist, ask)
	String df, vlist
	Variable ask
	
	Variable icnt, kill = 2
	String objName
	
	for (icnt = 0; icnt < ItemsInList(vlist); icnt += 1) // kill unused strings
	
		objName = StringFromList(icnt, vlist)
		
		if (ask == 1)
			Prompt kill, "kill variable " + NMQuotes( objName ) + "?", popup "no;yes;"
			DoPrompt "Encountered Unused Note Variable", kill
		endif
		
		if (kill == 2)
			KillStrings $(df+objName)
		endif
		
	endfor
	
End // NMNotesKillStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesClearFileVars()
	Variable ocnt
	String objName, ndf = NMNotesDF

	String fslist = NMNotesVarList(ndf, "F_", "string")
	String fnlist = NMNotesVarList(ndf, "F_", "numeric")

	for (ocnt = 0; ocnt < ItemsInList(fslist); ocnt += 1)
		objName = StringFromList(ocnt,fslist)
		SetNMstr(ndf+objName, "")
	endfor
	
	for (ocnt = 0; ocnt < ItemsInList(fnlist); ocnt += 1)
		objName = StringFromList(ocnt,fnlist)
		SetNMvar(ndf+objName, Nan)
	endfor
	
	if (WinType(NMNotesTableName) == 2)
		NMNotesTable( 0 )
	endif

End // NMNotesClearFileVars

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesCopyVars(df, prefix)
	String df // data folder to copy to
	String prefix // "H_" or "F_"
	
	String ndf = NMNotesDF
	
	if ((DataFolderExists(df) == 0) || (DataFolderExists(ndf) == 0))
		return -1
	endif
	
	Variable icnt
	String objName, slist, nlist
	
	slist = NMNotesVarList(ndf, prefix, "string")
	nlist = NMNotesVarList(ndf, prefix, "numeric")
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1) // string vars
		objName = StringFromList(icnt,slist)
		SetNMstr(df+objName, StrVarOrDefault(ndf+objName,""))
	endfor
	
	for (icnt = 0; icnt < ItemsInList(nlist); icnt += 1) // numeric vars
		objName = StringFromList(icnt,nlist)
		SetNMvar(df+objName, NumVarOrDefault(ndf+objName,Nan))
	endfor
	
End // NMNotesCopyVars

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesCopyToFolder(df) // save note variables to appropriate data folders
	String df // folder where to save Notes

	String cdf = NMClampDF, ndf = NMNotesDF
	String path = NMParent( df )
	
	df = RemoveEnding( df, ":" )
	path = RemoveEnding( path, ":" )
	
	if (DataFolderExists(path) == 0)
		return 0
	endif
	
	if (DataFolderExists(df) == 1)
		KillDataFolder $df
	endif
	
	if (DataFolderExists(df) == 1)
		return 0
	endif
	
	DuplicateDataFolder $ndf, $df

End // NMNotesCopyToFolder

//****************************************************************
//****************************************************************

Function NMNotesProgressPopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	PopupMenu NM_ProgWinPopup, mode=1, win=NMProgressPanel
	
	strswitch( popStr )
	
		case " ":
			return 0 // nothing
	
		default:

			Print popStr
			
	endswitch
	
	return 0

End // NMNotesProgressPopup

//****************************************************************
//****************************************************************

Function NMNotesAddNote(usernote) // add user note
	String usernote // string note or ("") to call prompt
	Variable icnt
	
	String ndf = NMNotesDF
	
	String varname, t = time()
	
	if (strlen(usernote) == 0)
 
		Prompt usernote "enter note:"
		DoPrompt "File Note (" + t + ")", usernote
		
		if (V_flag == 1)
			return 0 // cancel
		endif
		
	endif
	
	NMNotesTable2Vars()
	
	do
	
		varname = ndf + "F_Note" + num2istr(icnt)
		
		if (exists(varname) == 0)
			break
		elseif (strlen(StrVarOrDefault(varname, "")) == 0)
			break
		endif
		
		icnt += 1
		
	while(1)
	
	SetNMstr(varname, "[" + t + "] " + usernote)
	
	if (WinType(NMNotesTableName) == 2)
		NMNotesTable( 0 )
	endif

End // NMNotesAddNote

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesHeaderVar(varName, value)
	String varName
	Variable value
	
	String tName = NMNotesTableName
	
	if (StringMatch(varName[0,1], "H_") == 0)
		varName = "H_" + varName
	endif
	
	SetNMvar(NMNotesDF+varName, value)
	
	if (WinType(tName) == 2)
		NMNotesTable( 0 )
	endif

End // NMNotesHeaderVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesHeaderStr(varName, strValue)
	String varName
	String strValue
	
	String tName = NMNotesTableName
	
	if (StringMatch(varName[0,1], "H_") == 0)
		varName = "H_" + varName
	endif
	
	SetNMstr(NMNotesDF+varName, strValue)
	
	if (WinType(tName) == 2)
		NMNotesTable( 0 )
	endif

End // NMNotesHeaderStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesFileVar(varName, value)
	String varName
	Variable value
	
	String tName = NMNotesTableName
	
	if (StringMatch(varName[0,1], "F_") == 0)
		varName = "F_" + varName
	endif
	
	SetNMvar(NMNotesDF+varName, value)
	
	if (WinType(tName) == 2)
		NMNotesTable( 0 )
	endif

End // NMNotesFileVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesFileStr(varName, strValue)
	String varName
	String strValue
	
	String tName = NMNotesTableName
	
	if (StringMatch(varName[0,1], "F_") == 0)
		varName = "F_" + varName
	endif
	
	SetNMstr(NMNotesDF+varName, strValue)
	
	if (WinType(tName) == 2)
		NMNotesTable( 0 )
	endif

End // NMNotesFileStr

//****************************************************************
//****************************************************************
//****************************************************************

