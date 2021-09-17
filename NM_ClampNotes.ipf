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

StrConstant NMNotesDF = "root:Packages:NeuroMatic:ClampNotes:"
StrConstant NMNotesTableName = "CT0_NotesTable"
StrConstant NMNotesStr = ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
StrConstant NMNotesHeaderVarList = ""
StrConstant NMNotesHeaderStrList = "H_Name;H_Lab;H_Title;"
StrConstant NMNotesFileVarList = ""
StrConstant NMNotesFileStrList = "F_Folder;F_Stim;F_Tbgn;F_Tend;"

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNotesTable( type ) // create table to edit note vars
	Variable type // ( 0 ) clamp ( 1 ) review
	
	Variable ocnt, icnt, items
	String objName, df
	
	STRUCT Rect w
	
	String cdf = NMDF + "Clamp:"
	String ndf = NMNotesDF
	
	String tName = NMNotesTableName
	String tableTitle = "NM Data Acquisition Notes"
	
	if ( type == 1 )
	
		df = GetDataFolder( 1 )
	
		if ( DataFolderExists( df + "Notes:" ) )
			ndf = df + "Notes:"
		elseif ( DataFolderExists( df + "ClampNotes:" ) )
			ndf = df + "ClampNotes:"
		else
			return ""
		endif
		
		cdf = ndf
		
		tName = CurrentNMFolderPrefix() + "NotesTable"
		
		tableTitle += " : " + CurrentNMFolder( 0 )
		
	endif
	
	if ( !DataFolderExists( ndf ) )
		return ""
	endif
	
	String hslist = NMNotesVarList(ndf, "H_", "string")
	String hnlist = NMNotesVarList(ndf, "H_", "numeric")
	String fslist = NMNotesVarList(ndf, "F_", "string")
	String fnlist = NMNotesVarList(ndf, "F_", "numeric")
	String notelist = ListMatch(fslist, "*note*", ";") // note strings
	
	notelist = SortList(notelist, ";", 16)
	
	fnlist = RemoveFromList(NMNotesFileVarList, fnlist, ";")
	fslist = RemoveFromList(NMNotesFileStrList, fslist, ";")
	fslist = RemoveFromList(notelist, fslist, ";") // remove note strings
	
	items = ItemsInList(hslist) + ItemsInList(hnlist) + ItemsInList(fslist) + ItemsInList(fnlist)
	
	if ( items == 0 )
		return ""
	endif
	
	Make /O/T/N=(4*items) $(cdf+"VarName") = ""
	Make /O/T/N=(4*items) $(cdf+"StrValue") = ""
	Make /O/N=(4*items) $(cdf+"NumValue") = Nan
	
	Wave /T VarName = $(cdf+"VarName")
	Wave /T StrValue = $(cdf+"StrValue")
	Wave NumValue = $(cdf+"NumValue")
	
	if (WinType(tName) == 0)
	
		NMWinCascadeRect( w )
		
		Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) VarName, NumValue, StrValue as tableTitle
		
		ModifyTable /W=$tName title(Point)="Entry"
		ModifyTable /W=$tName alignment($cdf+"VarName")=0, alignment($cdf+"StrValue")=0
		ModifyTable /W=$tName width($cdf+"NumValue")=60, width($cdf+"StrValue")=200
		
		if ( type == 0 )
			//SetWindow $tName hook=NMNotesTableHook
		endif
		
	endif
	
	VarName[icnt] = "HEADER NOTES:"
	
	icnt += 1

	for (ocnt = 0; ocnt < ItemsInList(hslist); ocnt += 1)
		objName = StringFromList(ocnt,hslist)
		objName = NMNotesCheckVarName(objName)
		VarName[icnt] = objName
		StrValue[icnt] = StrVarOrDefault(ndf+objName,"")
		icnt += 1
	endfor
	
	for (ocnt = 0; ocnt < ItemsInList(hnlist); ocnt += 1)
		objName = StringFromList(ocnt,hnlist)
		objName = NMNotesCheckVarName(objName)
		VarName[icnt] = objName
		NumValue[icnt] = NumVarOrDefault(ndf+objName,Nan)
		StrValue[icnt] = NMNotesStr
		icnt += 1
	endfor
	
	icnt += 1
	
	VarName[icnt] = "FILE NOTES:"
	
	icnt += 2
	
	for (ocnt = 0; ocnt < ItemsInList(fnlist); ocnt += 1)
		objName = StringFromList(ocnt,fnlist)
		objName = NMNotesCheckVarName(objName)
		VarName[icnt] = objName
		NumValue[icnt] = NumVarOrDefault(ndf+objName,Nan)
		StrValue[icnt] = NMNotesStr
		icnt += 1
	endfor
	
	for (ocnt = 0; ocnt < ItemsInList(fslist); ocnt += 1)
		objName = StringFromList(ocnt,fslist)
		objName = NMNotesCheckVarName(objName)
		VarName[icnt] = objName
		StrValue[icnt] = StrVarOrDefault(ndf+objName,"")
		icnt += 1
	endfor
	
	icnt += 1
	
	for (ocnt = 0; ocnt < ItemsInList(notelist); ocnt += 1)
		objName = StringFromList(ocnt,notelist)
		objName = NMNotesCheckVarName(objName)
		VarName[icnt] = objName
		StrValue[icnt] = StrVarOrDefault(ndf+objName,"")
		icnt += 1
	endfor
	
	icnt += 1
	
	return tName

End // NMNotesTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesTableHook(infoStr)
	String infoStr
	
	String event= StringByKey("EVENT",infoStr)
	String win= StringByKey("WINDOW",infoStr)
	
	if (StringMatch(win, NMNotesTableName) == 0)
		return 0 // wrong window
	endif
	
	strswitch(event)
		case "deactivate":
		case "kill":
			//Execute /Z "NMNotesTable2Vars()" // update note values
	endswitch

End // NMNotesTableHook

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNotesVarList(ndf, prefix, varType)
	String ndf // notes data folder
	String prefix // prefix string ("H_" for Header, "F_" for File, "P_" for Progress button)
	String varType // "numeric" or "string"

	Variable ocnt, vtype = 2
	String objName, olist, vlist = ""
	
	if ( !DataFolderExists(ndf) )
		return ""
	endif
	
	if (StringMatch(varType, "string") == 1)
		vtype = 3
	endif
	
	olist = FolderObjectList(ndf, vtype)
	olist = RemoveFromList("FileType", olist)
	
	for (ocnt = 0; ocnt < ItemsInlist(olist); ocnt += 1)
		
		objName = StringFromList(ocnt, olist)
		
		if (StringMatch(prefix, objName[0,1]) == 1)
			vlist = AddListItem(objName, vlist, ";", inf)
		endif
		
	endfor
	
	return vlist

End // NMNotesVarList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNotesCheckVarName( objname ) // vars require prefix "H_" or "F_" or "P_"
	String objname
	
	String prefix
	
	objname = ReplaceString( "H_H_", objname, "H_" )
	objname = ReplaceString( "F_F_", objname, "F_" )
	objname = ReplaceString( "P_P_", objname, "P_" )
	
	prefix = objname[0,1]
	
	if ( StringMatch(prefix, "H_") || StringMatch(prefix, "F_") || StringMatch(prefix, "P_") )
		return objname // ok
	else
		return "F_" + objname // file var is default
	endif
	
End // NMNotesCheckVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMNotesPrint()
	
	Variable ocnt, items
	String objName, ndf
	
	String cdf = NMDF + "Clamp:"
	String df = GetDataFolder( 1 )
	
	if ( DataFolderExists( df + "Notes:" ) )
		ndf = df + "Notes:"
	elseif ( DataFolderExists( df + "ClampNotes:" ) )
		ndf = df + "ClampNotes:"
	else
		return -1
	endif
	
	Print "NM Data Acquisition Notes : " + GetDataFolder( 0 )
	
	String hslist = NMNotesVarList(ndf, "H_", "string")
	String hnlist = NMNotesVarList(ndf, "H_", "numeric")
	String fslist = NMNotesVarList(ndf, "F_", "string")
	String fnlist = NMNotesVarList(ndf, "F_", "numeric")
	String notelist = ListMatch(fslist, "*note*", ";") // note strings
	
	notelist = SortList(notelist, ";", 16)
	
	fnlist = RemoveFromList(NMNotesFileVarList, fnlist, ";")
	fslist = RemoveFromList(NMNotesFileStrList, fslist, ";")
	fslist = RemoveFromList(notelist, fslist, ";") // remove note strings
	
	items = ItemsInList(hslist) + ItemsInList(hnlist) + ItemsInList(fslist) + ItemsInList(fnlist)
	
	// header notes

	for (ocnt = 0; ocnt < ItemsInList(hslist); ocnt += 1)
	
		objName = StringFromList(ocnt,hslist)
		objName = NMNotesCheckVarName(objName)
		
		Print objName, " = ", StrVarOrDefault(ndf+objName,"")
		
	endfor
	
	for (ocnt = 0; ocnt < ItemsInList(hnlist); ocnt += 1)
	
		objName = StringFromList(ocnt,hnlist)
		objName = NMNotesCheckVarName(objName)
		
		Print objName, " = ", NumVarOrDefault(ndf+objName,Nan)
	
	endfor
	
	// file notes
	
	for (ocnt = 0; ocnt < ItemsInList(fnlist); ocnt += 1)
	
		objName = StringFromList(ocnt,fnlist)
		objName = NMNotesCheckVarName(objName)
		
		Print objName, " = ", NumVarOrDefault(ndf+objName,Nan)
	endfor
	
	for (ocnt = 0; ocnt < ItemsInList(fslist); ocnt += 1)
	
		objName = StringFromList(ocnt,fslist)
		objName = NMNotesCheckVarName(objName)
		
		Print objName, " = ", StrVarOrDefault(ndf+objName,"")
		
	endfor
	
	for (ocnt = 0; ocnt < ItemsInList(notelist); ocnt += 1)
	
		objName = StringFromList(ocnt,notelist)
		objName = NMNotesCheckVarName(objName)
		
		Print objName, " = ", StrVarOrDefault(ndf+objName,"")
		
	endfor
	
	return 0

End // NMNotesPrint

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMNotesBasicList(prefix, varType) // DEPRECATED
	String prefix // ("H") Header ("F") File
	Variable varType // (0) numeric (1) string
	
	strswitch(prefix)
	
		case "H":
			if (varType == 0)
				return NMNotesHeaderVarList
			else
				return NMNotesHeaderStrList
			endif
		
		case "F":
			if (varType == 0)
				return NMNotesFileVarList
			else
				return NMNotesFileStrList
			endif
			
	endswitch

End // NMNotesBasicList

//****************************************************************
//****************************************************************
//****************************************************************

