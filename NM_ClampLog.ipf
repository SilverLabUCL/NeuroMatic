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

StrConstant NMLogsDF = "root:NMLogs:"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogParent() // directory of log folders

	if (DataFolderExists(NMLogsDF) == 0)
		NewDataFolder $RemoveEnding( NMLogsDF, ":" )
	endif
	
	return NMLogsDF
	
End // LogParent

//****************************************************************
//****************************************************************
//****************************************************************

Function IsLogFolder(ldf)
	String ldf // log data folder
	
	return IsNMFolder(ldf, "NMLog")
	
End // IsLogFolder

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogFolderList()

	return NMFolderList("root:","NMLog")
	
End // LogFolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogSubfolderList(ldf)
	String ldf // log data folder
	
	return FolderObjectList(ldf, 4)
	
End // LogSubfolderList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogVarList(ndf, prefix, varType)
	String ndf // notes data folder
	String prefix // prefix string ("H_" for header, "F_" for file)
	String varType // "numeric" or "string"

	Variable ocnt, vtype = 2
	String objName, olist = ""
	
	if (DataFolderExists(ndf) == 0)
		return ""
	endif
	
	if (StringMatch(varType, "string") == 1)
		vtype = 3
	endif
	
	olist = FolderObjectList(ndf, vtype)
	olist = RemoveFromList("FileType", olist)
	
	return olist

End // LogVarList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogWaveList(ldf, type)
	String ldf // log data folder
	String type // ("H") Header ("F") File
	
	ldf = LastPathColon(ldf,1)
	
	Variable ocnt, add
	String objName, wnote = "", olist = ""
	
	do
	
		objName = GetIndexedObjName(ldf, 1, ocnt)
		
		if (strlen(objName) == 0)
			break // finished
		endif
		
		wnote = note($(ldf+objName))
		
		add = 1
		
		strswitch(type)
		
			case "H":
				if (StringMatch(wnote, "Header Notes") == 0)
					add = 0
				endif
				break
				
			case "F":
				if (StringMatch(wnote, "File Notes") == 0)
					add = 0
				endif
				break
				
		endswitch
		
		if (add == 1)
			olist = AddListItem(objName, olist, ";", inf)
		endif
		
		ocnt += 1
		
	while(1)
	
	return olist
	
End // LogWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function LogUpdateWaves(ldf) // create log waves from notes subfolders
	String ldf // log data folder
	Variable ocnt, icnt
	String objName, wname, flist, slist, nlist, tdf = ""
	
	ldf = LastPathColon(ldf,1)
	
	flist = LogSubfolderList(ldf)
	
	for (ocnt = 0; ocnt < ItemsInList(flist); ocnt += 1)
	
		objName = StringFromList(ocnt, flist)
		
		tdf = ldf + objName + ":"
		
		slist = LogVarList(tdf, "F_", "string")
		nlist = LogVarList(tdf, "F_", "numeric")
		
		for (icnt = 0; icnt < ItemsInList(slist); icnt += 1) // string vars
			objName = StringFromList(icnt,slist)
			wname = ldf+objName[2,inf]
			CheckNMtwave(wname, ocnt+1, "")
			SetNMtwave(wname, ocnt, StrVarOrDefault(tdf+objName, ""))
			Note /K $wname
			Note $wname, "File Notes"
		endfor
		
		for (icnt = 0; icnt < ItemsInList(nlist); icnt += 1) // numeric vars
			objName = StringFromList(icnt,nlist)
			wname = ldf+objName[2,inf]
			CheckNMwave(wname, ocnt+1, Nan)
			SetNMwave(wname, ocnt, NumVarOrDefault(tdf+objName, Nan))
			Note /K $wname
			Note $wname, "File Notes"
		endfor
		
		slist = LogVarList(tdf, "H_", "string")
		nlist = LogVarList(tdf, "H_", "numeric")
		
		for (icnt = 0; icnt < ItemsInList(slist); icnt += 1) // string vars
			objName = StringFromList(icnt,slist)
			wname = ldf+objName[2,inf]
			CheckNMtwave(wname, ocnt+1, "")
			SetNMtwave(wname, ocnt, StrVarOrDefault(tdf+objName, ""))
			Note /K $wname
			Note $wname, "Header Notes"
		endfor
		
		for (icnt = 0; icnt < ItemsInList(nlist); icnt += 1) // numeric vars
			objName = StringFromList(icnt,nlist)
			wname = ldf+objName[2,inf]
			CheckNMwave(wname, ocnt+1, Nan)
			SetNMwave(wname, ocnt, NumVarOrDefault(tdf+objName, Nan))
			Note /K $wname
			Note $wname, "Header Notes"
		endfor
		
	endfor

End // LogUpdateWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogTableName(ldf)
	String ldf // log data folder
	
	return NMFolderNameCreate( ldf, nmPrefix = 1 ) + "_table"
	
End // LogTableName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S LogNotebookName(ldf)
	String ldf // log data folder
	
	return NMFolderNameCreate( ldf, nmPrefix = 1 ) + "_notebook"
	
End // LogNotebookName

//****************************************************************
//****************************************************************
//****************************************************************

Function LogDisplayCall(ldf)
	String ldf

	Variable select = NumVarOrDefault( NMDF + "LogDisplaySelect", 1 )
	Prompt select, "choose display option:", popup "notebook;table;both;close;"
	DoPrompt "NM Clamp Log File Display", select
	
	if (V_flag == 1)
		return 0 // cancel
	endif
	
	SetNMvar( NMDF + "LogDisplaySelect", select )
	
	return NMLogDisplay( ldf, select, history = 1 )

End // LogDisplayCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMLogDisplay( ldf, select [ history ] )
	String ldf // log data folder
	Variable select // (1) notebook (2) table (3) both (4) kill
	Variable history
	
	String vlist = ""
	
	if ( history )
		vlist = NMCmdStr(ldf, vlist)
		vlist = NMCmdNum( select, vlist, integer = 1)
		NMCommandHistory(vlist)
	endif
	
	ldf = LastPathColon(ldf,1)
	
	switch( select )
		case 1:
			LogNotebook(ldf)
			break
		case 2:
			LogTable(ldf)
			break
		case 3:
			LogNotebook(ldf)
			LogTable(ldf)
			break
		case 4:
			LogNotebook(ldf, kill = 1)
			LogTable(ldf, kill = 1)
			KillDataFolder /Z $ldf
	endswitch
	
End // NMLogDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function LogTable(ldf [ kill ] ) // create a log table from a log data folder
	String ldf // log data folder
	Variable kill
	
	ldf = LastPathColon(ldf,1)
	
	Variable ocnt
	String objName, wlist, nlist
	String tName = LogTableName(ldf)
	String ftype = StrVarOrDefault(ldf+"FileType", "")
	
	STRUCT Rect w
	
	if (DataFolderExists(ldf) == 0)
		NMDoAlert("Error: data folder " + NMQuotes( ldf ) + " does not appear to exist.")
		return -1
	endif
	
	if (StringMatch(ftype, "NMLog") == 0)
		NMDoAlert("Error: data folder " + NMQuotes( ldf ) + " does not appear to be a NM Log folder.")
		return -1
	endif
	
	if ( kill )
		DoWindow /K $tName
		return 0
	endif
	
	LogUpdateWaves(ldf)
	
	if ( WinType( tName ) == 2 )
		DoWindow /F $tName
		return 0
	endif
	
	DoWindow /K $tName
	
	NMWinCascadeRect( w )
	Edit /K=(NMK())/N=$tName/W=(w.left,w.top,w.right,w.bottom) as "Clamp Log : " + NMChild( ldf )
	Execute "ModifyTable title(Point)= " + NMQuotes( "Entry" )
	
	wlist = LogWaveList(ldf, "F")
	
	nlist = ListMatch(wlist, "*note*", ";")
	nlist = SortList(nlist, ";", 16)
	
	wlist = RemoveFromList(nlist, wlist, ";") + nlist // place Note waves after others
	wlist += LogWaveList(ldf, "H") // place Header waves last
	
	for (ocnt = 0; ocnt < ItemsInList(wlist); ocnt += 1)
	
		objName = StringFromList(ocnt, wlist)
		
		RemoveFromTable $(ldf+objName) // remove wave first before appending
		AppendToTable $(ldf+objName)
		
		if (StringMatch(objName[0,3], "Note") == 1)
			Execute "ModifyTable alignment(" + ldf + objName + ")=0"
			Execute "ModifyTable width(" + ldf + objName + ")=150"
		endif
		
	endfor

End // LogTable

//****************************************************************
//****************************************************************
//****************************************************************

Function LogNotebook(ldf [ kill ] ) // create a log notebook from a log data folder
	String ldf // log data folder
	Variable kill
	
	String name, tabs
	
	ldf = LastPathColon(ldf,1)
	
	Variable ocnt
	String objName, olist, ftype = StrVarOrDefault(LastPathColon(ldf,1)+"FileType", "")
	
	STRUCT Rect w
	
	String nbName = LogNotebookName(ldf)
	
	if ((DataFolderExists(ldf) == 0) || (StringMatch(ftype, "NMLog") == 0))
		return 0
	endif
	
	if ( kill )
		DoWindow /K $nbName
		return 0
	endif
	
	if ( WinType( nbName ) == 5 )
		DoWindow /F $nbName
		return 0
	endif
	
	NMWinCascadeRect( w )
	
	DoWindow /K $nbName
	NewNotebook /K=(NMK())/F=0/N=$nbName/W=(w.left,w.top,w.right,w.bottom) as "Clamp Notebook : " + NMChild( ldf )
	
	Notebook $nbName text=("NeuroMatic Clamp Notebook")
	Notebook $nbName text=(NMCR + "FILE:\t\t\t\t\t" + StrVarOrDefault(ldf+"FileName", NMChild( ldf )))
	//Notebook $nbName text=(NMCR + "Created:\t\t\t\t" + StrVarOrDefault(ldf+"FileDate", ""))
	//Notebook $nbName text=(NMCR + "Time:\t\t\t\t" + StrVarOrDefault(ldf+"FileTime", ""))
	//Notebook $nbName text=(NMCR)
	
	olist = LogVarList(ldf, "H_", "string")
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
		objName = StringFromList(ocnt, olist)
		name = UpperStr(ReplaceString("H_", objName, "") + ":")
		tabs = LogNotebookTabs(name)
		Notebook $nbName text=(NMCR + name + tabs + StrVarOrDefault(ldf+objName, ""))
	endfor
	
	olist = LogVarList(ldf, "H_", "numeric")
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1)
		objName = StringFromList(ocnt, olist)
		name = UpperStr(ReplaceString("H_", objName, "") + ":")
		tabs = LogNotebookTabs(name)
		Notebook $nbName text=(NMCR + name + tabs + num2str(NumVarOrDefault(ldf+objName, Nan)))
	endfor
	
	olist = LogSubfolderList(ldf)
	
	for (ocnt = 0; ocnt < ItemsInList(olist); ocnt += 1) // loop thru Note subfolders
		objName = StringFromList(ocnt, olist)
		LogNotebookFileVars(LastPathColon(ldf,1) + objName + ":", nbName)
	endfor
	
End // LogNotebook

//****************************************************************
//****************************************************************
//****************************************************************

Function LogNotebookFileVars(ndf, nbName)
	String ndf // notes data folder
	String nbName
	String name, tabs

	if ((WinType(nbName) == 0) || (DataFolderExists(ndf) == 0))
		return 0
	endif
	
	Variable icnt, value
	String objName, strvalue
	
	String nlist = LogVarList(ndf, "F_", "numeric")
	String slist = LogVarList(ndf, "F_", "string")
	String notelist = ListMatch(slist, "*note*", ";") // note variables
	
	notelist = SortList(notelist, ";", 16)
	
	slist = RemoveFromList(notelist, slist, ";")
	
	Notebook $nbName selection={endOfFile, endOfFile}
	Notebook $nbName text=(NMCR)
	Notebook $nbName text=(NMCR + "************************************************************")
	
	for (icnt = 0; icnt < ItemsInList(slist); icnt += 1) // string vars
		objName = StringFromList(icnt,slist)
		name = ReplaceString("H_", objName, "") + ":"
		name = UpperStr(ReplaceString("F_", name, ""))
		tabs = LogNotebookTabs(name)
		Notebook $nbName text=(NMCR + name + tabs + StrVarOrDefault(ndf+objName, ""))
	endfor
	
	Notebook $nbName text=(NMCR)
	
	for (icnt = 0; icnt < ItemsInList(nlist); icnt += 1) // numeric vars
	
		objName = StringFromList(icnt,nlist)
		name = UpperStr(ReplaceString("F_", objName, "") + ":")
		tabs = LogNotebookTabs(name)
		value = NumVarOrDefault(ndf+objName, Nan)
		strvalue = ""
		
		if (numtype(value) == 0)
			strvalue = num2str(value)
		endif
		
		Notebook $nbName text=(NMCR + name + tabs + strvalue)
		
	endfor
	
	Notebook $nbName text=(NMCR)
	
	for (icnt = 0; icnt < ItemsInList(notelist); icnt += 1) // note vars
	
		objName = StringFromList(icnt,notelist)
		name = UpperStr(ReplaceString("F_", objName, "") + ":")
		tabs = LogNotebookTabs(name)
		strvalue = StrVarOrDefault(ndf+objName, "")
		
		if (strlen(strvalue) > 0)
			Notebook $nbName text=(NMCR + name + tabs + strvalue)
		endif
		
	endfor
	
End // LogNotebookFileVars

//****************************************************************
//****************************************************************
//****************************************************************

Function /T LogNotebookTabs(name)
	String name
	
	if (strlen(name) < 4)
		return "\t\t\t\t\t"
	elseif (strlen(name) < 7)
		return "\t\t\t\t"
	elseif (strlen(name) < 10)
		return "\t\t\t"
	elseif (strlen(name) < 13)
		return "\t\t"
	else
		return "\t"
	endif

End // LogNotebookTabs

//****************************************************************
//****************************************************************
//****************************************************************