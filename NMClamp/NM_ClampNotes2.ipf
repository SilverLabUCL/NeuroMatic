#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright ( C ) 2017 Jason Rothman
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// ( at your option ) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
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
	String cdf = ConfigDF( "ClampNotes" )
	
	if ( !DataFolderExists( ndf ) )
		return -1
	endif

	String name = StrVarOrDefault( ndf + "H_Name", "" )
	String lab = StrVarOrDefault( ndf + "H_Lab", "" )
	String title = StrVarOrDefault( ndf + "H_Title", "" )
	
	Prompt name, "enter user name:"
	Prompt lab, "enter user lab/affiliation:"
	Prompt title, "experiment title:"
	DoPrompt "Edit User Name and Lab", name, lab, title
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	SetNMstr( ndf + "H_Name", name )
	SetNMstr( ndf + "H_Lab", lab )
	SetNMstr( ndf + "H_Title", title )
	
	SetNMstr( cdf + "H_Name", name )
	SetNMstr( cdf + "H_Lab", lab )
	SetNMstr( cdf + "H_Title", title )

End // NMNotesEditHeader

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesBasicUpdate()
	
	String ndf = NMNotesDF
	String cdf = ConfigDF( "ClampNotes" )
	String df = GetDataFolder( 0 )
	String stim = StimCurrent()
	String tstart = StrVarOrDefault( "FileTime", "" )
	String tend = StrVarOrDefault( "FileFinish", "" )
	
	if ( !DataFolderExists( ndf ) )
		return -1
	endif
	
	SetNMstr( ndf + "F_Folder", df )
	SetNMstr( ndf + "F_Stim", stim )
	SetNMstr( ndf + "F_Tbgn", tstart )
	SetNMstr( ndf + "F_Tend", tend )
	
	SetNMstr( cdf + "F_Folder", df )
	SetNMstr( cdf + "F_Stim", stim )
	SetNMstr( cdf + "F_Tbgn", tstart )
	SetNMstr( cdf + "F_Tend", tend )
	
End // NMNotesBasicUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampNotesCheck() // auto run via NM Package function
	
	String ndf = NMNotesDF
	
	if ( !DataFolderExists( ndf ) )
		return -1
	endif
	
	SetNMstr( ndf + "FileType", "NMNotes" )
	
	// Header string/numeric parameters begin with "H_"
	
	// NMNotesHeaderStrList = "H_Name;H_Lab;H_Title;"
	NMNotesStrCheck( "H_Name", strValue="Your Name", description="Your name" )
	NMNotesStrCheck( "H_Lab", strValue="Your Lab/Address", description="Your lab/address" )
	NMNotesStrCheck( "H_Title", strValue="Your Experiment Title", description="Your experiment title" )
	
	//NMNotesVarCheck( "H_Age", numValue=Nan, units="days", description="Age" )
	
	// File string/numeric parameters begin with "F_"
	
	// NMNotesFileStrList = "F_Folder;F_Stim;F_Tbgn;F_Tend;"
	NMNotesStrCheck( "F_Folder", strValue="", description="NM data folder" )
	NMNotesStrCheck( "F_Stim", strValue="", description="NM stim" )
	NMNotesStrCheck( "F_Tbgn", strValue="", description="Acquisition start time" )
	NMNotesStrCheck( "F_Tend", strValue="", description="Acquisition end time" )
	
	//NMNotesStrCheck( "F_Drug", strValue="", description="Experimental drug" )
	
	NMNotesVarCheck( "F_Temp", numValue=Nan, units="°C", description="temperature" )
	NMNotesVarCheck( "F_Relectrode", numValue=Nan, units="MOhms", description="electrode resistance, computed via Rstep()" )
	NMNotesVarCheck( "F_Rs", numValue=Nan, units="MOhms", description="electrode series resistance" )
	NMNotesVarCheck( "F_Cm", numValue=Nan, units="pF", description="cell capacitance" )
	
	// Progress Button string parameters begin with "P_"
	
	//NMNotesStrCheck( "P_TTX", strValue="Added 100 nM TTX" )
	
	return 0

End // NMClampNotesCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMClampNotesConfigs() // auto run via NM Package function

	String cdf = ConfigDF( "ClampNotes" )
	String ndf = NMNotesDF

	SetNMvar( cdf + "C_NoCleanUp", 1 )
	
	NMClampNotesCheck()

End // NMClampNotesConfigs

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesAddPrompt( typeHFP )
	String typeHFP // "H" for Header, "F" for File, "P" for Progress button
	
	String title, varName = "", varName2, typeNS = "numeric", units = "", description = ""
	Variable numValue = NaN
	String strValue = "", typeExists, psList
	
	String ndf = NMNotesDF
	
	if ( !DataFolderExists( ndf ) )
		return -1
	endif 
	
	Prompt varName "enter parameter name:"
	Prompt typeNS "select parameter type:", popup "numeric;text;"
	Prompt numValue "enter parameter value:"
	Prompt units "units:"
	Prompt description "description:"
	Prompt strValue "enter parameter text:"
	
	strswitch( typeHFP )
		case "H": // header
			title = "NM Clamp Notes : Add Header Parameter"
			typeNS = "text"
			break
		case "F": // file
			title = "NM Clamp Notes : Add File Parameter"
			typeNS = "numeric"
			break
		case "P": // Progress button
			title = "NM Clamp Notes : Add Progress Button Note"
			typeNS = "text"
			psList = NMNotesVarList( ndf, "P_", "string" )
			varName = "Button" + num2istr( ItemsInList( psList ) ) // default name
			Prompt varName "enter button name:"
			Prompt strValue "enter note text:"
	endswitch
	
	if ( StringMatch( typeHFP, "P" ) )
		DoPrompt title, varName
	else
		DoPrompt title, varName, typeNS
	endif
	
	if ( ( V_flag == 1 ) || ( strlen( varName ) == 0 ) )
		return 0 // cancel
	endif
	
	varName2 = typeHFP + "_" + varName
	varName2 = NMNotesCheckVarName( varName2 )
	
	typeExists = NMConfigTypeNS( "ClampNotes", varName2 )
	
	strswitch( typeExists )
		case "N":
			DoAlert /T=title 0, NMQuotes( varName ) + " already exists as a numeric parameter"
			return -1
		case "S":
			DoAlert /T=title 0, NMQuotes( varName ) + " already exists as a text parameter"
			return -1
	endswitch
	
	if ( StringMatch( typeNS, "numeric" ) )
		DoPrompt title, numValue, units, description
	else
		DoPrompt title, strValue, description // string values do not have units
	endif
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	varName = typeHFP + "_" + varName
	
	if ( StringMatch( typeNS, "numeric" ) )
		return NMNotesVarCheck( varName, numValue = numValue, units = units, description = description, setValue = 1 )
	endif
	
	if ( StringMatch( typeNS, "text" ) )
		return NMNotesStrCheck( varName, strValue = strValue, units = units, description = description, setValue = 1 )
	endif
	
End // NMNotesAddPrompt

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesVarCheck( varName [ numValue, units, description, setValue ] )
	String varName
	Variable numValue
	String units
	String description
	Variable setValue
	
	String typeNS, varName2, varName3
	
	String ndf = NMNotesDF
	
	if ( ParamIsDefault( numValue ) )
		numValue = NaN
	endif
	
	if ( ParamIsDefault( units ) )
		units = ""
	endif
	
	if ( ParamIsDefault( description ) )
		description = ""
	endif
	
	if ( !DataFolderExists( ndf ) )
		return -1
	endif
	
	varName = NMNotesCheckVarName( varName )
	varName2 = "T_" + varName
	varName3 = "D_" + varName
	
	typeNS = NMConfigTypeNS( "ClampNotes", varName )
	
	if ( StringMatch( typeNS, "S" ) == 1 )
		return -1 // aleady exists as string variable
	endif
	
	if ( setValue )
		SetNMvar( ndf + varName, numValue )
		SetNMstr( ndf + varName2, units )
		SetNMstr( ndf + varName3, description )
	else
		CheckNMvar( ndf + varName, numValue )
		CheckNMstr( ndf + varName2, units )
		CheckNMstr( ndf + varName3, description )
	endif
	
	NMConfigVar( "ClampNotes", varName, numValue, description, units )
	
	return 0
	
End // NMNotesVarCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesStrCheck( varName [ strValue, units, description, setValue ] )
	String varName
	String strValue
	String units
	String description
	Variable setValue
	
	String typeNS, varName2, varName3
	
	String ndf = NMNotesDF
	
	if ( ParamIsDefault( strValue ) )
		strValue = ""
	endif
	
	if ( ParamIsDefault( units ) )
		units = ""
	endif
	
	if ( ParamIsDefault( description ) )
		description = ""
	endif
	
	if ( !DataFolderExists( ndf ) )
		return -1
	endif
	
	varName = NMNotesCheckVarName( varName )
	varName2 = "T_" + varName
	varName3 = "D_" + varName
	
	typeNS = NMConfigTypeNS( "ClampNotes", varName )
	
	if ( StringMatch( typeNS, "N" ) )
		return -1 // aleady exists as numeric variable
	endif
	
	if ( setValue )
		SetNMstr( ndf + varName, strValue )
		SetNMstr( ndf + varName2, units )
		SetNMstr( ndf + varName3, description )
	else
		CheckNMstr( ndf + varName, strValue )
		CheckNMstr( ndf + varName2, units )
		CheckNMstr( ndf + varName3, description )		
	endif
	
	NMConfigStr( "ClampNotes", varName, strValue, description, units )
	
	return 0
	
End // NMNotesStrCheck

//****************************************************************
//****************************************************************

Function /S NMNotesProgressButtonList( [ removePrefix ] )
	Variable removePrefix

	Variable icnt
	String varName, buttonText, psList2 = ""
	
	String ndf = NMNotesDF
	String psList = NMNotesVarList( ndf, "P_", "string" )
	
	for ( icnt = 0 ; icnt < ItemsInList( psList ) ; icnt += 1 )
	
		varName = StringFromList( icnt, psList )
		buttonText = StrVarOrDefault( ndf + varName, "" )
		
		if ( strlen( buttonText ) > 0 )
			psList2 += varName + ";"
		endif
		
	endfor
	
	if ( removePrefix )
		return ReplaceString( "P_", psList2, "" )
	else
		return psList2
	endif

End // NMNotesProgressButtonList

//****************************************************************
//****************************************************************

Function NMNotesProgressPopup( ctrlName ) : ButtonControl
	String ctrlName
	
	Variable buttonNum
	String varName, buttonText
	
	String ndf = NMNotesDF
	String psList = NMNotesVarList( ndf, "P_", "string" )
	
	if ( ItemsInList( psList ) == 0 )
		return 0
	endif
	
	buttonNum = str2num( ReplaceString( "NM_ProgWinButton", ctrlName, "" ) )
	
	varName = StringFromList( buttonNum, psList )
	
	buttonText = StrVarOrDefault( ndf + varName, "" )
	
	if ( strlen( buttonText ) > 0 )
		NMNotesAddNote( buttonText )
	endif
	
	return 0

End // NMNotesProgressPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesClearFileVars()

	Variable ocnt
	String objName
	
	String ndf = NMNotesDF
	
	if ( !DataFolderExists( ndf ) )
		return -1
	endif

	String fslist = NMNotesVarList( ndf, "F_", "string" )
	String fnlist = NMNotesVarList( ndf, "F_", "numeric" )

	for ( ocnt = 0; ocnt < ItemsInList( fslist ); ocnt += 1 )
	
		objName = StringFromList( ocnt,fslist )
		
		if ( StringMatch( objName[ 0, 5 ] "F_Note" ) )
			KillStrings /Z $ndf + objName
		else
			SetNMstr( ndf + objName, "" )
		endif
		
	endfor
	
	for ( ocnt = 0; ocnt < ItemsInList( fnlist ); ocnt += 1 )
		objName = StringFromList( ocnt,fnlist )
		SetNMvar( ndf + objName, Nan )
	endfor
	
	//if ( WinType( NMNotesTableName ) == 2 )
		//NMNotesTable( 0 )
	//endif

End // NMNotesClearFileVars

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesCopyVars( df, prefix )
	String df // data folder to copy to
	String prefix // "H_" or "F_"
	
	Variable icnt, numValue
	String objName, strValue, slist, nlist
	
	String ndf = NMNotesDF
	
	if ( !DataFolderExists( df ) || !DataFolderExists( ndf ) )
		return -1
	endif
	
	slist = NMNotesVarList( ndf, prefix, "string" )
	nlist = NMNotesVarList( ndf, prefix, "numeric" )
	
	for ( icnt = 0; icnt < ItemsInList( slist ); icnt += 1 ) // string vars
		objName = StringFromList( icnt, slist )
		strValue = StrVarOrDefault( ndf + objName, "" )
		SetNMstr( df + objName, strValue )
	endfor
	
	for ( icnt = 0; icnt < ItemsInList( nlist ); icnt += 1 ) // numeric vars
		objName = StringFromList( icnt, nlist )
		numValue = NumVarOrDefault( ndf + objName, Nan )
		SetNMvar( df + objName, numValue )
	endfor
	
End // NMNotesCopyVars

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesCopyToFolder( df ) // save note variables to appropriate data folders
	String df // folder where to save Notes

	String ndf = NMNotesDF
	String path = NMParent( df )
	
	df = RemoveEnding( df, ":" )
	path = RemoveEnding( path, ":" )
	
	if ( !DataFolderExists( path ) )
		return 0
	endif
	
	if ( DataFolderExists( df ) )
		KillDataFolder $df
	endif
	
	if ( DataFolderExists( df ) )
		return 0
	endif
	
	DuplicateDataFolder $ndf, $df

End // NMNotesCopyToFolder

//****************************************************************
//****************************************************************

Function NMNotesAddNote( usernote [ history ] ) // add user note
	String usernote // string note or ( "" ) to call prompt
	Variable history
	
	Variable icnt
	String txt, varName, strValue, t = time()
	
	String df = NMNotesDF
	
	if ( ParamIsDefault( history ) )
		history = 1
	endif
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	if ( strlen( usernote ) == 0 )
 
		Prompt usernote "enter note:"
		DoPrompt "File Note (" + t + ")", usernote
		
		if ( ( V_flag == 1 ) || ( strlen( usernote ) == 0 ) ) 
			return 0 // cancel
		endif
		
	endif
	
	//NMNotesTable2Vars()
	
	do
	
		varName = df + "F_Note" + num2istr( icnt )
		strValue = StrVarOrDefault( varname, "" )
		
		if ( exists( varName ) == 0 )
			break
		elseif ( strlen( strValue ) == 0 )
			break
		endif
		
		icnt += 1
		
	while( icnt < 1000 )
	
	txt = "[" + t + "] " + usernote
	
	SetNMstr( varName, txt )
	
	if ( history )
		NMHistory( "NM Clamp Note " + txt )
	endif
	
	//if ( WinType( NMNotesTableName ) == 2 )
		//NMNotesTable( 0 )
	//endif
	
	return 0

End // NMNotesAddNote

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesFileVar( varName, value )
	String varName
	Variable value
	
	String ndf = NMNotesDF
	
	if ( !DataFolderExists( ndf ) )
		return -1
	endif
	
	if ( StringMatch( varName[0,1], "F_" ) == 0 )
		varName = "F_" + varName
	endif
	
	SetNMvar( ndf + varName, value )
	
	//if ( WinType( NMNotesTableName ) == 2 )
		//NMNotesTable( 0 )
	//endif

End // NMNotesFileVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesFileStr( varName, strValue )
	String varName
	String strValue
	
	String ndf = NMNotesDF
	
	if ( !DataFolderExists( ndf ) )
		return -1
	endif
	
	if ( StringMatch( varName[0,1], "F_" ) == 0 )
		varName = "F_" + varName
	endif
	
	SetNMstr( ndf + varName, strValue )
	
	//if ( WinType( NMNotesTableName ) == 2 )
		//NMNotesTable( 0 )
	//endif

End // NMNotesFileStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesTable2Vars_DEPRECATED()

	Variable icnt, objNum, type, nitem, sitem
	String objName, objStr
	
	String cdf = NMClampDF
	String df = NMNotesDF
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	String nlist = NMNotesVarList( df, "H_", "numeric" ) + NMNotesVarList( df, "F_", "numeric" )
	String slist = NMNotesVarList( df, "H_", "string" ) + NMNotesVarList( df, "F_", "string" )
	
	nlist = RemoveFromList( NMNotesFileVarList, nlist, ";" )
	slist = RemoveFromList( NMNotesFileStrList, slist, ";" )
	
	String tName = NMNotesTableName

	if ( WinType( tName ) != 2 )
		return 0 // table doesnt exist
	endif
	
	if ( WaveExists( $cdf+"VarName" ) == 0 )
		return 0 // waves dont exist
	endif
	
	Wave /T VarName = $cdf+"VarName"
	Wave /T StrValue = $cdf+"StrValue"
	Wave NumValue = $cdf+"NumValue"
	
	for ( icnt = 0; icnt < numpnts( VarName ); icnt += 1 )
	
		objName = VarName[icnt]
		
		if ( strlen( objName ) == 0 )
			continue
		endif
		
		if ( StringMatch( objName, "Header Notes:" ) == 1 )
			continue
		endif
		
		if ( StringMatch( objName, "File Notes:" ) == 1 )
			continue
		endif
		
		objName = NMNotesCheckVarName( objName )
		
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
		
		nitem = WhichListItem( objName, nlist, ";", 0, 0 )
		sitem = WhichListItem( objName, slist, ";", 0, 0 )
		
		if ( nitem >= 0 ) // numeric variable
			type = 1
			nlist = RemoveListItem( nitem, nlist )
			//objNum = NMNotesCheckNumValue( objName, objStr, objNum )
		elseif ( sitem >= 0 ) // string variable
			type = 2
			slist = RemoveListItem( sitem, slist )
			//objStr = NMNotesCheckStrValue( objName, objStr, objNum )
		endif

		if ( type == 0 )
			if ( strlen( objStr ) > 0 )
				type = 2
				//objStr = NMNotesCheckStrValuex( objName, objStr, objNum )
			else
				type = 1
			endif
		endif
		
		KillStrings /Z $df + objName
		KillVariables /Z $df + objName
		
		if ( type == 1 )
			SetNMvar( df + objName, objNum )
		elseif ( type == 2 )
			SetNMstr( df + objName, objStr )
		endif
		
	endfor
	
	// kill deleted variables
	
	//NMNotesKillVar( df, nlist, 0 )
	//NMNotesKillStr( df, slist, 0 )
	
End // NMNotesTable2Vars

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesCheckNumValue_DEPRECATED( varName, strValue, numValue )
	String varName, strValue
	Variable numValue
	
	if ( ( strlen( strValue ) > 0 ) && ( StringMatch( strValue, NMNotesStr ) == 0 ) )
	
		if ( numtype( numValue ) > 0 )
			numValue = str2num( strValue )
		endif
		
		Prompt numValue, varName
		DoPrompt "Please Check Numeric Input Value", numValue
		
		if ( V_flag == 1 )
			numValue = Nan // cancel
		endif
		
	endif
	
	return numValue

End // NMNotesCheckNumValue

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNotesCheckStrValue_DEPRECATED( varName, strValue, numValue )
	String varName, strValue
	Variable numValue
	
	if ( numtype( numValue ) == 0 )
	
		if ( strlen( strValue ) == 0 )
			strValue += num2str( numValue )
		else
			strValue += " : " + num2str( numValue )
		endif
		
		Prompt strValue, varName
		DoPrompt "Please Check String Input Value", strValue
		
		if ( V_flag == 1 )
			strValue = "" // cancel
		endif
		
	endif
	
	return strValue

End // NMNotesCheckStrValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesKillVar_DEPRECATED( df, vlist, ask )
	String df, vlist
	Variable ask
	
	Variable icnt, kill = 2
	String objName
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	for ( icnt = 0; icnt < ItemsInList( vlist ); icnt += 1 ) // kill unused variables
	
		objName = StringFromList( icnt, vlist )
		
		if ( ask == 1 )
			Prompt kill, "kill variable " + NMQuotes( objName ) + "?", popup "no;yes;"
			DoPrompt "Encountered Unused Note Variable", kill
		endif
		
		if ( kill == 2 )
			KillVariables $df + objName
		endif
		
	endfor
	
End // NMNotesKillVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesKillStr_DEPRECATED( df, vlist, ask )
	String df, vlist
	Variable ask
	
	Variable icnt, kill = 2
	String objName
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	for ( icnt = 0; icnt < ItemsInList( vlist ); icnt += 1 ) // kill unused strings
	
		objName = StringFromList( icnt, vlist )
		
		if ( ask == 1 )
			Prompt kill, "kill variable " + NMQuotes( objName ) + "?", popup "no;yes;"
			DoPrompt "Encountered Unused Note Variable", kill
		endif
		
		if ( kill == 2 )
			KillStrings $df + objName
		endif
		
	endfor
	
End // NMNotesKillStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesHeaderVar_DEPRECATED( varName, value )
	String varName
	Variable value
	
	String df = NMNotesDF
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	if ( StringMatch( varName[0,1], "H_" ) == 0 )
		varName = "H_" + varName
	endif
	
	SetNMvar( df + varName, value )
	
	//if ( WinType( NMNotesTableName ) == 2 )
		//NMNotesTable( 0 )
	//endif

End // NMNotesHeaderVar

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesHeaderStr_DEPRECATED( varName, strValue )
	String varName
	String strValue
	
	String df = NMNotesDF
	
	if ( !DataFolderExists( df ) )
		return -1
	endif
	
	if ( StringMatch( varName[0,1], "H_" ) == 0 )
		varName = "H_" + varName
	endif
	
	SetNMstr( df + varName, strValue )
	
	//if ( WinType( NMNotesTableName ) == 2 )
		//NMNotesTable( 0 )
	//endif

End // NMNotesHeaderStr

//****************************************************************
//****************************************************************
//****************************************************************

