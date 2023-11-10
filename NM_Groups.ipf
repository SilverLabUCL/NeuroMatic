#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

//****************************************************************
//****************************************************************
//
//	NeuroMatic: data aquisition, analyses and simulation software that runs with the Igor Pro environment
//	Copyright (C) 2024 The Silver Lab, UCL
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
//	Groups
//
//	Set and Get functions:
//
//		NMGroupsSet( [ on, waveNum, group, numGroups, groupSeq, fromWave, toWave, blocks, clearFirst, conversionWave, prefixFolder ] )
//
//	Useful Functions:
//
//		NMGroupsClear( [ prefixFolder, update, history ] )
//		NMGroupsPanel( [ history ] )
//
//****************************************************************
//****************************************************************

Constant NMFirstGroup = 0

StrConstant NMGroupsPanelName = "NM_GroupsPanel"

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsOK()

	String prefixFolder = CurrentNMPrefixFolder()

	if ( ( strlen( prefixFolder ) > 0 ) && DataFolderExists( prefixFolder ) )
		return 1
	endif
	
	NMDoAlert( "No Groups. You may need to select " + NMQuotes( "Wave Prefix" ) + " first." )
	
	return 0

End // NMGroupsOK

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMGroups( [ prefixFolder ] )
	String prefixFolder

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	String gwName = NMGroupsWaveName( prefixFolder = prefixFolder )
	
	if ( WaveExists( $gwName ) == 1 )

		if ( NMGroupsWaveToLists( gwName, prefixFolder = prefixFolder ) >= 0 )
			KillWaves /Z $gwName
		endif
	
	endif
	
	return 0
	
End // CheckNMGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMGroups( [ prefixFolder ] )
	String prefixFolder

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif

	if ( ( strlen( prefixFolder ) > 0 ) && DataFolderExists( prefixFolder ) )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
	endif
	
	UpdateNMPanel( 0 )
	NMCurrentWaveSet( Nan, prefixFolder = prefixFolder, update = 0 )
	NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
	UpdateNMPanelSets( 1 )
		
End // UpdateNMGroups

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsSet( [ on, waveNum, group, numGroups, groupSeq, fromWave, toWave, blocks, clearFirst, conversionWave, prefixFolder, update, history ] )
	Variable on // ( 0 ) Groups off ( 1 ) Groups on
	
	Variable waveNum // wave number ( used with group )
	Variable group // group number ( used with waveNum )
	
	Variable numGroups // number of groups, or use groupSeq to specify sequence
	String groupSeq // sequence string "0;1;2;3;" or "0-3"
	Variable fromWave // starting wave number
	Variable toWave // ending wave number, ( inf ) for all
	Variable blocks // number of blocks in each group ( default = 1 )
	Variable clearFirst // clear all groups before defining sequence ( 0 ) no ( 1 ) yes
	
	String conversionWave
	
	String prefixFolder
	
	Variable update // do not update NM
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable updateNM
	String vlist = "", vlist2 = "", vlist3 = "", returnStr = ""
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( !ParamIsDefault( on ) )
	
		vlist = NMCmdNumOptional( "on", on, vlist, integer = 1 )
	
		on = BinaryCheck( on )
	
		if ( on != NMVarGet( "GroupsOn" ) )
			SetNMvar( NMDF+"GroupsOn", on )
			updateNM = 1
		endif
		
	endif
	
	if ( ParamIsDefault( prefixFolder ) )
	
		prefixFolder = CurrentNMPrefixFolder()
		
	else
	
		if ( strlen( prefixFolder ) > 0 )
			vlist2 = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist2 )
		elseif ( NMPrefixFolderHistory && ( strlen( prefixFolder ) == 0 ) )
			prefixFolder = CurrentNMPrefixFolder()
			vlist2 = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist2 )
		endif
		
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
		
	endif
	
	if ( !ParamIsDefault( group ) )
	
		if ( ParamIsDefault( waveNum ) )
			waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
		endif
		
		vlist = NMCmdNumOptional( "waveNum", waveNum, vlist, integer = 1 )
		vlist = NMCmdNumOptional( "group", group, vlist, integer = 1 )
	
		z_GroupSet( prefixFolder, waveNum, group )
		
		updateNM = 1
		
		returnStr = num2str( group )
		
		SetNMvar( NMDF+"GroupsOn", 1 )
		
	elseif ( !ParamIsDefault( conversionWave ) )
	
		vlist = NMCmdStrOptional( "conversionWave", conversionWave, vlist )
	
		NMGroupsConvert( conversionWave, prefixFolder = prefixFolder, update = 1 )
		
		SetNMvar( NMDF+"GroupsOn", 1 )
	
	else
	
		if ( ParamIsDefault( fromWave ) )
			fromWave = 0
		else
			vlist3 = NMCmdNumOptional( "fromWave", fromWave, vlist3, integer = 1 )
		endif
		
		if ( ParamIsDefault( toWave ) )
			toWave = inf
		else
			vlist3 = NMCmdNumOptional( "toWave", toWave, vlist3, integer = 1 )
		endif
		
		if ( ParamIsDefault( blocks ) )
			blocks = 1
		else
			vlist3 = NMCmdNumOptional( "blocks", blocks, vlist3, integer = 1 )
		endif
		
		if ( ParamIsDefault( clearFirst ) )
			clearFirst = 1
		else
			vlist3 = NMCmdNumOptional( "clearFirst", clearFirst, vlist3, integer = 1 )
		endif
	
		if ( !ParamIsDefault( numGroups ) )
		
			if ( numtype( numGroups ) > 0 )
				NM2Error( 10, "numGroups", num2str( numGroups ) )
				return ""
			endif
			
			numGroups = abs( numGroups )
			
			vlist = NMCmdNumOptional( "numGroups", numGroups, vlist, integer = 1 )
			vlist += vlist3
			
			if ( numGroups == 0 )
				groupSeq = ""
			else
				groupSeq = num2istr( NMFirstGroup ) + "," + num2istr( NMFirstGroup + numGroups - 1 )
			endif
			
			returnStr = z_GroupsSeqSet( prefixFolder, groupSeq, fromWave, toWave, blocks, clearFirst )
		
			updateNM = 1
			
			SetNMvar( NMDF+"GroupsOn", 1 )
			
		elseif ( !ParamIsDefault( groupSeq ) )
		
			vlist = NMCmdStrOptional( "groupSeq", groupSeq, vlist )
			vlist += vlist3
		
			returnStr = z_GroupsSeqSet( prefixFolder, groupSeq, fromWave, toWave, blocks, clearFirst )
			
			updateNM = 1
			
			SetNMvar( NMDF+"GroupsOn", 1 )
			
		endif
	
	endif
	
	if ( history )
		NMCommandHistory( vlist + vlist2 )
	endif
	
	if ( update && updateNM )
		UpdateNMGroups( prefixFolder = prefixFolder )
	endif
	
	return returnStr

End // NMGroupsSet

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_GroupSet( prefixFolder, waveNum, group )
	String prefixFolder // prefix folder, full path
	Variable waveNum // wave number ( -1 ) for current
	Variable group // group number ( NaN ) for no group
	
	Variable gcnt, ccnt, numChannels, numWaves
	String groupName, groupList, wName
	
	String fxn = GetRTStackInfo( 2 )
	
	if ( strlen( prefixFolder ) == 0 )
		return NMError( 21, fxn, "prefixFolder", prefixFolder )
	endif
	
	if ( !DataFolderExists( prefixFolder ) )
		return NMError( 30, fxn, "prefixFolder", prefixFolder )
	endif
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) || ( waveNum >= numWaves ) )
		return NM2Error( 10, "waveNum", num2istr( waveNum ) )
	endif
	
	if ( ( numtype( group ) > 0 ) || ( group < 0 ) )
		group = NaN
	else
		group = round( group )
	endif
	
	groupName = NMGroupsName( group )
	
	NMGroupsRemove( waveNum, prefixFolder = prefixFolder )
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		wName = NMChanWaveName( ccnt, waveNum, prefixFolder = prefixFolder )
		
		if ( strlen( groupName ) > 0 )
			NMSetsWaveListAdd( wName, groupName, ccnt, prefixFolder = prefixFolder )
		endif
		
		z_GroupSetWaveNote( wName, group )
		
	endfor
		
	return 0

End // z_GroupSet

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_GroupSetWaveNote( wName, group )
	String wName
	Variable group
	
	String txt
	
	String groupName = NMGroupsName( group )
	
	if ( NMNoteExists( wName, "Group" ) == 1 )
	
		NMNoteVarReplace( wName, "Group", group )
		
		return 0
	
	endif
	
	if ( WaveExists( $wName ) == 1 )
	
		txt = note( $wName )
		
		Note /K $wName
		
		Note $wName, "Group:" + num2str( group )
		Note $wName, txt
	
	endif
	
End // z_GroupSetWaveNote

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S z_GroupsSeqSetCall()
	
	String groupSeq, vlist = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( NMGroupsOK() == 0 )
		return ""
	endif
	
	Variable numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	Variable numGroups = NMGroupsNumCount( prefixFolder = prefixFolder )
	Variable firstGroup = NMGroupsFirst( "", prefixFolder = prefixFolder )
	Variable fromWave = NumVarOrDefault( prefixFolder+"GroupsFromWave", 0 )
	Variable toWave = NumVarOrDefault( prefixFolder+"GroupsToWave", numWaves - 1 )
	Variable blocks = NumVarOrDefault( prefixFolder+"GroupsWaveBlocks", 1 )
	Variable clearFirst = 1 + NumVarOrDefault( prefixFolder+"GroupsClearFirst", 1 )
	
	if ( ( numtype( numGroups ) > 0 ) || ( numGroups < 1 ) )
		numGroups = NMGroupsNumDefault( prefixFolder = prefixFolder )
	endif
	
	if ( ( numtype( firstGroup ) > 0 ) || ( firstGroup < 0 ) )
		firstGroup = NMFirstGroup
	endif
	
	Prompt numGroups, "number of groups:"
	Prompt firstGroup, "first group number:"
	Prompt fromWave, "define sequence from wave:"
	Prompt toWave, "define sequence to wave:"
	Prompt blocks, "in blocks of:"
	Prompt clearFirst, "clear Groups first?", popup "no;yes"
	
	DoPrompt "Define Group Sequence", numGroups, firstGroup, fromWave, toWave, blocks, clearFirst
	
	if ( V_flag == 1 )
		return "" // user cancelled
	endif
	
	clearFirst -= 1
	
	SetNMvar( prefixFolder+"NumGrps" , numGroups )
	SetNMvar( prefixFolder+"FirstGrp" , firstGroup )
	SetNMvar( prefixFolder+"GroupsFromWave" , fromWave )
	SetNMvar( prefixFolder+"GroupsToWave" , toWave )
	SetNMvar( prefixFolder+"GroupsWaveBlocks" , blocks )
	SetNMvar( prefixFolder+"GroupsClearFirst" , clearFirst )
	
	groupSeq = num2istr( firstGroup ) + "-" + num2istr( firstGroup + numGroups - 1 )
	
	//groupSeq = RangeToSequenceStr( groupSeq )
	
	prefixFolder = CurrentNMPrefixFolder()
	
	NMGroupsSet( groupSeq = groupSeq, fromWave = fromWave, toWave = toWave, blocks = blocks, clearFirst = clearFirst, prefixFolder = "", history = 1 )
	
	return groupSeq

End // z_GroupsSeqSetCall

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S z_GroupsSeqSet( prefixFolder, groupSeq, fromWave, toWave, blocks, clearFirst )
	String prefixFolder
	String groupSeq // seq string "0;1;2;3;" or "0-3" for range
	Variable fromWave // starting wave number
	Variable toWave // ending wave number, ( inf ) for all
	Variable blocks // number of blocks in each group ( default = 1 )
	Variable clearFirst // clear all groups before defining sequence ( 0 ) no ( 1 ) yes
	
	Variable bcnt, ccnt, wcnt, gcnt, gcnt2
	Variable numChannels, numWaves, group
	String groupSeqStr, groupSeqStr2, groupName
	String wName, wList = ""
	
	String fxn = GetRTStackInfo( 2 )
	
	if ( strlen( prefixFolder ) == 0 )
		return NMErrorStr( 21, fxn, "prefixFolder", prefixFolder )
	endif
	
	if ( !DataFolderExists( prefixFolder ) )
		return NMErrorStr( 30, fxn, "prefixFolder", prefixFolder )
	endif
	
	if ( ( numtype( fromWave ) > 0 ) || ( fromWave < 0 ) )
		fromWave = 0
	endif
	
	if ( ( numtype( toWave ) > 0 ) || ( toWave < 0 ) )
		toWave = inf
	endif
	
	if ( ( numtype( blocks ) > 0 ) || ( blocks <= 0 ) )
		blocks = 1
	endif
	
	clearFirst = BinaryCheck( clearFirst )
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( ( numtype( numChannels ) > 0 ) || ( numChannels <= 0 ) )
		return ""
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )

	if ( ( numtype( fromWave ) > 0 ) || ( fromWave < 0 ) || ( fromWave > numWaves-1 ) )
		fromWave = 0
	endif
	
	if ( ( numtype( toWave ) > 0 ) || ( toWave < 0 ) || ( toWave > numWaves-1 ) )
		toWave = numWaves - 1
	endif
	
	blocks = max( blocks, 1 )
	
	if ( ( strsearch( groupSeq, "-", 0 ) > 0 ) || ( strsearch( groupSeq, ",", 0 ) > 0 ) )
		groupSeq = RangeToSequenceStr( groupSeq )
	endif
	
	if ( clearFirst == 1 )
		NMGroupsClear( prefixFolder = prefixFolder, update = 0 )
	endif
	
	if ( ItemsInList( groupSeq ) == 0 )
		return ""
	endif
	
	for ( gcnt = 0 ; gcnt < ItemsInList( groupSeq ) ; gcnt += 1 )
	
		groupSeqStr = StringFromList( gcnt, groupSeq )
		group = str2num( groupSeqStr )
		groupName = NMGroupsName( group )
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )

			wList = ""
			gcnt2 = 0
			bcnt = 0
			
			for ( wcnt = fromWave; wcnt <= toWave; wcnt += 1 )
				
				groupSeqStr2 = StringFromList( gcnt2, groupSeq )
				
				if ( StringMatch( groupSeqStr, groupSeqStr2 ) == 1 )
					//z_GroupSet( wcnt, str2num( groupSeqStr ), 0 ) // SLOW
					wName = NMChanWaveName( ccnt, wcnt, prefixFolder = prefixFolder )
					wList += wName + ";"
				endif
				
				bcnt += 1
				
				if ( bcnt == blocks )
				
					bcnt = 0
					gcnt2 += 1
					
					if ( gcnt2 >= ItemsInList( groupSeq ) )
						gcnt2 = 0
					endif
				
				endif
				
			endfor
			
			NMSetsWaveListRemove( wList, groupName, ccnt, prefixFolder = prefixFolder )
			NMSetsWaveListAdd( wList, groupName, ccnt, prefixFolder = prefixFolder )
			
			for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
				wName = StringFromList( wcnt, wList )
				z_GroupSetWaveNote( wName, group )
			endfor
		
		endfor
	
	endfor
	
	SetNMstr( prefixFolder+"GroupsSeqStr" , groupSeq )
	
	return groupSeq

End // z_GroupsSeqSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsCall( fxn, select )
	String fxn
	String select
	
	Variable snum = str2num( select )
	
	strswitch( fxn )
	
		case "On":
			NMGroupsSet( on = 1, history = 1 )
			return 0
			
		case "Off":
			NMGroupsSet( on = 0, history = 1 )
			return 0
			
		case "On/Off": // toggle
			if ( NMVarGet( "GroupsOn" ) )
				NMGroupsSet( on = 0, history = 1 )
			else
				NMGroupsSet( on = 1, history = 1 )
			endif
			
	endswitch
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif

	strswitch( fxn )
			
		case "Define":
			z_GroupsSeqSetCall()
			return 0
	
		case "Clear":
		case "Kill":
			return NMGroupsClearCall()
			
		case "Convert":
			return NMGroupsConvertCall()
			
		case "Table":
		case "Panel":
		case "Edit":
		case "Edit Panel":
			return NMGroupsPanel( history = 1 )
			
		default:
		
			snum = str2num( fxn[7,inf] )
			
			if ( numtype( snum ) > 0 )
				break
			endif
		
			if ( StringMatch( fxn[0,6], "Groups=" ) == 1 )
				NMGroupsSet( groupSeq = "0," + num2istr( snum - 1 ), fromWave = 0, toWave = inf, blocks = 1, clearFirst = 1 )
			elseif ( StringMatch( fxn[0,6], "Blocks=" ) == 1 )
				NMGroupsSet( groupSeq = "0," + num2istr( snum - 1 ), fromWave = 0, toWave = inf, blocks = snum, clearFirst = 1 )
			else
				NMDoAlert( "NMGroupsCall: unrecognized function call: " + fxn )
			endif
			
	endswitch
	
	return -1
	
End // NMGroupsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsName( group )
	Variable group
		
	if ( numtype( group ) == 0 )
		return "Group" + num2istr( group )
	endif
	
	return ""

End // NMGroupsName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsWaveList( group, chanNum [ prefixFolder ] )
	Variable group // group number
	Variable chanNum // channel number
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return NMSetsWaveList( NMGroupsName( group ), chanNum, prefixFolder = prefixFolder )
	
End // NMGroupsWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsRemove( waveNum [ prefixFolder ] )
	Variable waveNum
	String prefixFolder
	
	Variable gcnt, ccnt, removeFromAll, numChannels, numWaves
	String groupSeqStr, groupList, wName, groupName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( ( numtype( numChannels ) > 0 ) || ( numChannels < 0 ) )
		return NM2Error( 10, "numChannels", num2istr( numChannels ) )
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( ( numtype( numWaves ) > 0 ) || ( numWaves < 0 ) )
		return NM2Error( 10, "numWaves", num2istr( numWaves ) )
	endif
	
	if ( waveNum < 0 )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	endif
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) || ( waveNum >= numWaves ) )
		return NM2Error( 10, "waveNum", num2istr( waveNum ) )
	endif
	
	groupList = NMGroupsList( 1, prefixFolder = prefixFolder )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
		wName = NMChanWaveName( ccnt, waveNum, prefixFolder = prefixFolder )
		
		groupSeqStr = NMGroupsNumStrWaveNote( wName )
		
		removeFromAll = 0
		
		if ( strlen( groupSeqStr ) == 0 ) // Group wave note does not exist
		
			removeFromAll = 1
		
		else
		
			if ( StringMatch( groupSeqStr, "NaN" ) == 1 ) // wave is not in a Group
			
				// nothing to do
				
			elseif ( numtype( str2num( groupSeqStr ) ) == 0 )
			
				groupName = "Group" + groupSeqStr
				
				if ( WhichListItem( groupName, groupList, ";", 0 ) < 0 )
					removeFromAll = 1 // could not find Group, something is wrong
				else
					NMSetsWaveListRemove( wName, groupName, ccnt, prefixFolder = prefixFolder )
					z_GroupSetWaveNote( wName, NaN )
				endif
			
			endif
		
		endif
		
		if ( removeFromAll == 1 )
		
			for ( gcnt = 0 ; gcnt < ItemsInList( groupList ) ; gcnt += 1 )
				groupName = StringFromList( gcnt, groupList )
				NMSetsWaveListRemove( wName, groupName, ccnt, prefixFolder = prefixFolder )
			endfor
			
			z_GroupSetWaveNote( wName, NaN )
		
		endif
		
	endfor
	
	return 0
	
End // NMGroupsRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsNumStrWaveNote( wName )
	String wName
	
	Variable icnt, group
	
	if ( WaveExists( $wName ) == 0 )
		return ""
	endif
	
	//return StringByKey( "Group", NMNoteString( wName ) )
	
	String noteStr = note( $wName )
	
	noteStr = noteStr[0, 1000] // make smaller
	
	icnt = strsearch( noteStr, "Group:", 0, 2 )
	
	if ( icnt < 0 )
		return ""
	endif
	
	group = GetNumFromStr( noteStr, "Group:" )
	
	return num2str( group )
	
End // NMGroupsNumStrWaveNote

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsWaveNoteClear( [ prefixFolder ] )
	String prefixFolder

	Variable ccnt, wcnt, numChannels
	String wList, wName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		wList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
		
		for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
		
			wName = StringFromList( wcnt, wList )
			z_GroupSetWaveNote( wName, NaN )
			
		endfor
		
	endfor
	
	return 0

End // NMGroupsWaveNoteClear

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsList( type [ prefixFolder ] )
	Variable type // ( 0 ) e.g. "0;1;2;" ( 1 ) e.g. "Group0;Group1;Group2;"
	String prefixFolder
	
	Variable scnt
	String setName, setList, groupList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	setList = NMSetsListAll( prefixFolder = prefixFolder )
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( StringMatch( setName[ 0, 4 ], "Group" ) == 1 )
		
			if ( type == 1 )
				groupList = AddListItem( setName, groupList, ";", inf )
			else
				groupList = AddListItem( setName[ 5, inf ], groupList, ";", inf )
			endif
			
		endif
		
	endfor
	
	if ( type == 1 )
		return SortList( groupList, ";", 16 )
	else
		return SortList( groupList, ";", 2 )
	endif

End // NMGroupsList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupNameCheck( groupName [ prefixFolder ] )
	String groupName
	String prefixFolder
	
	String groupList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	groupList = NMGroupsList( 1, prefixFolder = prefixFolder )
	
	if ( WhichListItem( groupName, groupList ) >= 0 )
		return 1
	else
		return 0
	endif

End // NMGroupNameCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupCheck( group [ prefixFolder ] )
	Variable group
	String prefixFolder
	
	String groupList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	groupList = NMGroupsList( 0, prefixFolder = prefixFolder )
	
	if ( WhichListItem( num2istr( group ), groupList ) >= 0 )
		return 1
	else
		return 0
	endif

End // NMGroupCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNumCount( [ prefixFolder ] )
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif

	return ItemsInList( NMGroupsList( 0, prefixFolder = prefixFolder ) )

End // NMGroupsNumCount

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsFirst( groupSeq [ prefixFolder ] ) // first group number
	String groupSeq // e.g. "0;1;2;" or ( "" ) for current groupSeq
	String prefixFolder

	Variable gcnt, group, firstGroup = inf
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	if ( ItemsInList( groupSeq ) == 0 )
		groupSeq = NMGroupsList( 0, prefixFolder = prefixFolder )
	endif
	
	for ( gcnt = 0 ; gcnt < ItemsInList( groupSeq ) ; gcnt += 1 )
	
		group = str2num( StringFromList( gcnt, groupSeq ) )
		
		if ( ( numtype( group ) == 0 ) && ( group < firstGroup ) )
			firstGroup = group
		endif
		
	endfor
	
	return firstGroup // e.g. "0"

End // NMGroupsFirst

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsLast( groupSeq [ prefixFolder ] ) // last group number
	String groupSeq // e.g. "0;1;2;" or ( "" ) for current groupSeq
	String prefixFolder

	Variable gcnt, group, lastGroup = 0
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	if ( ItemsInList( groupSeq ) == 0 )
		groupSeq = NMGroupsList( 0, prefixFolder = prefixFolder )
	endif
	
	for ( gcnt = 0 ; gcnt < ItemsInList( groupSeq ) ; gcnt += 1 )
	
		group = str2num( StringFromList( gcnt, groupSeq ) )
		
		if ( ( numtype( group ) == 0 ) && ( group > lastGroup ) )
			lastGroup = group
		endif
		
	endfor
	
	return lastGroup // e.g. "2"

End // NMGroupsLast

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNum( waveNum [ prefixFolder ] ) // determine group number from wave number
	Variable waveNum // wave number, or ( -1 ) for current
	String prefixFolder
	
	Variable gcnt, ccnt, group, numChannels, numWaves
	String groupList, groupSeqStr, wList, wName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( numChannels <= 0 )
		return NaN
	endif
	
	if ( ( numtype( waveNum ) > 0 ) || ( waveNum < 0 ) )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( numWaves <= 0 )
		return NaN
	endif
	
	if ( ( waveNum < 0 ) || ( waveNum >= numWaves ) )
		return Nan
	endif
	
	groupList = NMGroupsList( 0, prefixFolder = prefixFolder )
	
	if ( ItemsInList( groupList ) == 0 )
		return Nan
	endif
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		wName = NMChanWaveName( ccnt, waveNum, prefixFolder = prefixFolder )
		
		groupSeqStr = NMGroupsNumStrWaveNote( wName )
		
		if ( strlen( groupSeqStr ) > 0 )
	
			return str2num( groupSeqStr )
			
		else
		
			for ( gcnt = 0 ; gcnt < ItemsInList( groupList ) ; gcnt += 1 )
	
				group = str2num( StringFromList( gcnt, groupList ) )
				
				wList = NMGroupsWaveList( group, ccnt, prefixFolder = prefixFolder )
				
				if ( WhichListItem( wName, wList ) >= 0 )
					return group
				endif
				
			endfor
		
		endif
	
	endfor
	
	return Nan
	
End // NMGroupsNum

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsStr( group )
	Variable group
	
	if ( numtype( group ) == 0 )
		 return num2istr( group )
	else
		return ""
	endif

End // NMGroupsStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsClearCall()

	DoAlert 2, "Are you sure you want to clear all Groups?"
	
	if ( V_Flag != 1 )
		return 0 // chancel
	endif
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	return NMGroupsClear( prefixFolder = prefixFolder, history = 1 )

End // NMGroupsClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsClear( [ prefixFolder, update, history ] )
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String groupList, vlist = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	groupList = NMGroupsList( 1, prefixFolder = prefixFolder )
	
	NMSetsKill( groupList, prefixFolder = prefixFolder, update = 0 )
	NMGroupsWaveNoteClear( prefixFolder = prefixFolder )
	
	if ( update )
		UpdateNMGroups( prefixFolder = prefixFolder )
	endif
	
	return 0
			
End // NMGroupsClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsConvertCall()

	String conversionWave = " ", wList, vlist = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wList = " ;" + WaveList( "*", ";", "Text:0" )
	
	Prompt conversionWave, "select a wave containing your Group sequence:", popup wList
	DoPrompt "Convert a wave to Groups", conversionWave

	if ( ( V_flag == 1 ) || !WaveExists( $conversionWave ) )
		return -1 // cancel
	endif
	
	prefixFolder = CurrentNMPrefixFolder( fullPath = 0 )
	
	NMGroupsSet( conversionWave = conversionWave, prefixFolder = "", history = 1 )
	
	return 0

End // NMGroupsConvertCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsConvert( conversionWave [ prefixFolder, update ] )
	String conversionWave
	String prefixFolder
	Variable update
	
	String gwName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	gwName = NMGroupsWaveName( prefixFolder = prefixFolder )
	
	if ( WaveExists( $conversionWave ) == 0 )
		return NM2Error( 1, "conversionWave", conversionWave )
	endif
	
	Duplicate /O $conversionWave $gwName
	
	NMGroupsWaveToLists( gwName, prefixFolder = prefixFolder )
	
	KillWaves /Z $gwName
	
	if ( update )
		UpdateNMGroups( prefixFolder = prefixFolder )
	endif

	return 0
	
End // NMGroupsConvert

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNumDefault( [ prefixFolder ] )
	String prefixFolder

	Variable numGroups
	String groupList, subStimFolder = SubStimDF()
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	groupList = NMGroupsList( 0, prefixFolder = prefixFolder )

	numGroups = ItemsInList( groupList )
	
	if ( ( numGroups == 0 ) && ( strlen( prefixFolder ) > 0 ) )
		numGroups = NumVarOrDefault( prefixFolder+"NumGrps", 0 )
	endif
	
	if ( ( numGroups == 0 ) && ( strlen( subStimFolder ) > 0 ) )
		numGroups = NumVarOrDefault( subStimFolder+"NumStimWaves", 0 )
	endif
	
	if ( numGroups == 0 )
		numGroups = 3
	endif
	
	return numGroups

End // NMGroupsNumDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsNumFromStr( groupStr )
	String groupStr // string containing group number (e.g. "Group0", or "Set1 x Group1" )
	
	Variable group, icnt
	
	Variable ibgn = strsearch( groupStr, "Group", 0, 2 )
	
	if ( strsearch( groupStr, "All Groups", 0, 2 ) >= 0 )
		return Nan
	endif
	
	if ( ibgn < 0 )
		return Nan
	endif
	
	ibgn += 5
	
	for ( icnt = ibgn; icnt < strlen( groupStr ); icnt += 1 )
		if ( numtype( str2num( groupStr[ibgn,ibgn] ) ) > 0 )
			break
		endif
	endfor
	
	group = str2num( groupStr[ ibgn, icnt-1 ] )
	
	return group
	
End // NMGroupsNumFromStr

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Groups Wave Functions ( old "Group" wave )
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMGroupsWaveName( [ prefixFolder ] )
	String prefixFolder

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	return prefixFolder + "Group"

End // NMGroupsWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsWaveToLists( gwName [ prefixFolder ] )
	String gwName
	String prefixFolder

	Variable gcnt, ccnt, wcnt, group, numChannels
	String wName, groupSeqStr, groupName, groupList = "", wList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( WaveExists( $gwName ) == 0 )
		return NM2Error( 10, "gwName", gwName )
	endif
	
	Wave wtemp = $gwName
	
	for ( wcnt = 0 ; wcnt < numpnts( wtemp ) ; wcnt += 1 )
	
		group = wtemp[ wcnt ]
		
		if ( ( numtype( group ) == 0 ) && ( group >= 0 ) )
			groupList = NMAddToList( num2istr( group ), groupList, ";" )
		endif
	
	endfor
	
	groupList = SortList( groupList, ";", 2 )
	
	NMGroupsClear( prefixFolder = prefixFolder, update = 0 )
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( gcnt = 0 ; gcnt < ItemsInList( groupList ) ; gcnt += 1 )
		
		groupSeqStr = StringFromList( gcnt, groupList )
		group = str2num( groupSeqStr )
		groupName = NMGroupsName( group )
		
		for ( ccnt = 0 ; ccnt < numChannels; ccnt += 1 )
		
			wList = ""
		
			for ( wcnt = 0 ; wcnt < numpnts( wtemp ) ; wcnt += 1 )
			
				if ( wtemp[ wcnt ] == group )
					wName = NMChanWaveName( ccnt, wcnt, prefixFolder = prefixFolder )
					wList += wName + ";"
				endif
				
			endfor
			
			NMSetsWaveListRemove( wList, groupName, ccnt, prefixFolder = prefixFolder )
			NMSetsWaveListAdd( wList, groupName, ccnt, prefixFolder = prefixFolder )
			
			for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
				wName = StringFromList( wcnt, wList )
				z_GroupSetWaveNote( wName, group )
			endfor
		
		endfor
	
	endfor
	
	return 0
	
End // NMGroupsWaveToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsListsToWave( gwName [ prefixFolder ] )
	String gwName
	String prefixFolder

	Variable wcnt, ccnt, gcnt, group, found, numChannels, numWaves, alertUser = 0
	String wName2, groupList, wList

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( ( numChannels <= 0 ) || ( numWaves <= 0 ) )
		return 0
	endif
	
	if ( WaveExists( $gwName ) == 1 )
	
		if ( alertUser == 1 )
	
			DoAlert 1, "NMGroupsListsToWave Alert: wave " + NMQuotes( gwName ) + " already exists. Do you want to overwrite it?"
			
			if ( V_flag != 1 )
				return -1 // cancel
			endif
		
		endif
		
		KillWaves /Z $gwName // try to kill
		
	endif

	groupList = NMGroupsList( 0, prefixFolder = prefixFolder )
	
	Make /O/N=(numWaves) $gwName = Nan
	
	NMGroupsTag( gwName, prefixFolder = prefixFolder )
	
	if ( ItemsInList( groupList ) == 0 )
		return 0
	endif
	
	Wave wtemp = $gwName
	
	for ( wcnt = 0 ; wcnt < numWaves; wcnt += 1 )
	
		found = Nan
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
			wName2 = NMChanWaveName( ccnt, wcnt, prefixFolder = prefixFolder )
			
			for ( gcnt = 0 ; gcnt < ItemsInlist( groupList ) ; gcnt += 1 )
	
				group = str2num( StringFromList( gcnt, groupList ) )
				wList = NMGroupsWaveList( group, ccnt, prefixFolder = prefixFolder )
				
				if ( WhichListItem( wName2, wList ) >= 0 )
					found = group
					break
				endif
				
			endfor
			
			if ( numtype( found ) == 0 )
				break
			endif
			
		endfor
		
		if ( wcnt < numpnts( wtemp ) )
			wtemp[ wcnt ] = found
		endif
		
	endfor
	
	return 0

End // NMGroupsListsToWave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsTag( groupList [ prefixFolder ] )
	String groupList
	String prefixFolder
	
	Variable icnt
	String wName, wnote, prefix
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	prefix = NMChild( prefixFolder )
	prefix = ReplaceString( NMPrefixSubfolderPrefix, prefix, "" )
	
	for ( icnt = 0; icnt < ItemsInList( groupList ); icnt += 1 )
	
		wName = StringFromList( icnt, groupList )
		
		if ( WaveExists( $wName ) == 0 )
			continue
		endif
		
		if ( StringMatch( NMNoteStrByKey( wName, "Type" ), "NMGroup" ) == 1 )
			continue
		endif
		
		wnote = "WPrefix:" + prefix
		NMNoteType( wName, "NMGroup", "Wave#", "Group", wnote )
		
		Note $wName, "DEPRECATED: Group waves are no longer utilized by NeuroMatic. Please use Group list string variables instead."
		
	endfor
	
	return 0

End // NMGroupsTag

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsListsUpdateNewChannels( [ prefixFolder ] )
	String prefixFolder
	
	String gwName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	gwName = NMGroupsWaveName( prefixFolder = prefixFolder )

	KillWaves /Z $gwName
	
	NMGroupsListsToWave( gwName, prefixFolder = prefixFolder )
	
	NMGroupsWaveToLists( gwName, prefixFolder = prefixFolder )

	KillWaves /Z $gwName
	
	return 0

End // NMGroupsListsUpdateNewChannels

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Groups Panel Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanel( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable autoSave, ccnt, x1, x2, y1, y2
	Variable width = 600, height = 375
	Variable x0 = 44, y0 = 45, xinc = 85, yinc = 35
	
	String wName
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	if ( NMGroupsOK() == 0 )
		return -1
	endif
	
	Variable xpixels = NMScreenPixelsX()
	Variable fs = NMPanelFsize
	
	String tname = NMGroupsPanelName + "Table"
	String child = NMGroupsPanelName + "#" + tname
	
	String prefixFolder = CurrentNMPrefixFolder()
	String currentPrefix = CurrentNMWavePrefix()
	
	String gwName = NMGroupsWaveName( prefixFolder = prefixFolder )
	
	Variable numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	SetNMvar( NMDF+"GroupsOn", 1 )
	
	KillWaves /Z $gwName
	
	NMGroupsListsToWave( gwName, prefixFolder = prefixFolder )
	
	NMGroupsPanelDefaults()
	
	x1 = 20 + ( xpixels - width ) / 2
	y1 = 140 + 40
	x2 = x1 + width
	y2 = y1 + height
	
	if ( WinType( NMGroupsPanelName ) == 7 )
		DoWindow /F $NMGroupsPanelName
	else
		DoWindow /K $NMGroupsPanelName
		NewPanel /K=1/N=$NMGroupsPanelName/W=( x1,y1,x2,y2 ) as "Groups"
		SetWindow $NMGroupsPanelName hook(groupspanel)=NMGroupsPanelHook
	endif
	
	DoWindow /T $NMGroupsPanelName, "Edit Groups : " + CurrentNMFolder( 0 ) + " : " + currentPrefix
	
	GroupBox NM_GrpsPanelBox, title = "Group Sequence ( 01230123... )", pos={x0-20,y0-30}, size={245,240}, fsize=fs
	
	SetVariable NM_NumGroups, title="number of Groups: ", limits={1,inf,0}, pos={x0,y0}, size={200,50}, fsize=fs
	SetVariable NM_NumGroups, value=$( prefixFolder+"NumGrps" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_FirstGroup, title="first Group: ", limits={0,inf,0}, pos={x0,y0+1*yinc}, size={200,50}, fsize=fs
	SetVariable NM_FirstGroup, value=$( prefixFolder+"FirstGrp" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_SeqStr, title="sequence: ", pos={x0,y0+2*yinc}, size={200,50}, fsize=fs, frame=0
	SetVariable NM_SeqStr, value=$( prefixFolder+"GroupsSeqStr" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_WaveStart, title="start at wave: ", limits={0,inf,0}, pos={x0,y0+3*yinc}, size={200,50}, fsize=fs
	SetVariable NM_WaveStart, value=$( prefixFolder+"GroupsFromWave" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_WaveEnd, title="end at wave: ", limits={0,inf,0}, pos={x0,y0+4*yinc}, size={200,50}, fsize=fs
	SetVariable NM_WaveEnd, value=$( prefixFolder+"GroupsToWave" ), proc=NMGroupsPanelSetVariable
	
	SetVariable NM_WaveBlocks, title="in blocks of: ", limits={1,inf,0}, pos={x0,y0+5*yinc}, size={200,50}, fsize=fs
	SetVariable NM_WaveBlocks, value=$( prefixFolder+"GroupsWaveBlocks" ), proc=NMGroupsPanelSetVariable
	
	y0 += 20
	
	Button NM_Execute, title="\K("+NMRedStr+")Execute", pos={x0,y0+6*yinc}, size={90,20}, fsize=fs, proc=NMGroupsPanelButton
	Button NM_Clear, title="Clear", pos={x0+1*110,y0+6*yinc}, size={90,20}, fsize=fs, proc=NMGroupsPanelButton
	
	Button NM_Save, title="Save", pos={x0,y0+7*yinc}, size={90,20}, fsize=fs, proc=NMGroupsPanelButton
	Button NM_Close, title="Close", pos={x0+1*110,y0+7*yinc}, size={90,20}, fsize=fs, proc=NMGroupsPanelButton
	
	autoSave = NumVarOrDefault( NMDF+"GroupsPanelAutoSave", 1 )
	
	CheckBox NM_SaveAuto, title="Auto Save", pos={x0+70,y0+8*yinc}, size={16,18}, proc=NMGroupsPanelCheckBox, fsize=fs, value=autoSave
	
	NMGroupsPanelUpdate( 1 )
	
End // NMGroupsPanel

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelUpdate( updateTable )
	Variable updateTable // ( 0 ) no ( 1 ) yes
	
	Variable dis, disableAll = 0

	String prefixFolder = CurrentNMPrefixFolder()
	String currentPrefix = CurrentNMWavePrefix()

	if ( WinType( NMGroupsPanelName ) != 7 )
		KillWaves /Z $NMGroupsWaveName( prefixFolder = prefixFolder )
		return 0
	endif
	
	NMGroupsPanelDefaults()
	
	Variable autoSave = NumVarOrDefault( NMDF+"GroupsPanelAutoSave", 1 )
	
	if ( strlen( prefixFolder ) == 0 )
		disableAll = 2
	endif
	
	DoWindow /T $NMGroupsPanelName, "Edit Groups : " + CurrentNMFolder( 0 ) + " : " + currentPrefix
	
	GroupBox NM_GrpsPanelBox, win=$NMGroupsPanelName, disable=disableAll
	
	SetVariable NM_NumGroups, win=$NMGroupsPanelName, disable=disableAll, value=$( prefixFolder+"NumGrps" )
	
	SetVariable NM_FirstGroup, win=$NMGroupsPanelName, disable=disableAll, value=$( prefixFolder+"FirstGrp" )
	
	SetVariable NM_SeqStr, win=$NMGroupsPanelName, disable=disableAll, value=$( prefixFolder+"GroupsSeqStr" )
	
	SetVariable NM_WaveStart, win=$NMGroupsPanelName, disable=disableAll, value=$( prefixFolder+"GroupsFromWave" )
	
	SetVariable NM_WaveEnd, win=$NMGroupsPanelName, disable=disableAll, value=$( prefixFolder+"GroupsToWave" )
	
	SetVariable NM_WaveBlocks, win=$NMGroupsPanelName, disable=disableAll, value=$( prefixFolder+"GroupsWaveBlocks" )
	
	Button NM_Execute, win=$NMGroupsPanelName, disable=disableAll
	Button NM_Clear, win=$NMGroupsPanelName, disable=disableAll
	
	dis = 0
	
	if ( ( autoSave == 1 ) || ( disableAll == 2 ) )
		dis = 2
	endif
	
	Button NM_Save, win=$NMGroupsPanelName, disable=dis
	
	CheckBox NM_SaveAuto, win=$NMGroupsPanelName, disable=disableAll
	
	if ( updateTable == 1 )
		NMGroupsPanelTable( 1 )
	endif

End // NMGroupsPanelUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelTable( addWavesToTable )
	Variable addWavesToTable // ( 0 ) no ( 1 ) yes
	
	Variable numChannels, ccnt, wcnt, x1 = 300, x2 = 1500, y1 = 0, y2 = 1000
	String wname, wList
	
	String prefixFolder = CurrentNMPrefixFolder()
	String currentPrefix = CurrentNMWavePrefix()
	
	String gwName = NMGroupsWaveName( prefixFolder = prefixFolder )
	
	String tname = NMGroupsPanelName + "Table"
	String child = NMGroupsPanelName + "#" + tname
	
	if ( WinType( NMGroupsPanelName ) != 7 )
		return -1
	endif
	
	String clist = ChildWindowList( NMGroupsPanelName )
	
	if ( WhichListItem( tname, clist ) < 0 )
	
		Edit /Host=$NMGroupsPanelName/N=$tname/W=( x1, y1, x2, y2 )
		
	else
		
		wList = NMWindowWaveList( child, 1, 1 )
	
		for ( wcnt = 0; wcnt < ItemsInList( wList ); wcnt += 1 )
			RemoveFromTable /W=$child $StringFromList( wcnt, wList )
		endfor
		
	endif
	
	ModifyTable /W=$child title( Point )= currentPrefix
	
	if ( addWavesToTable == 0 )
		return 0
	endif
		
	if ( WaveExists( $gwName ) == 1 )
		AppendToTable /W=$child $gwName
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		wname = NMChanWaveListName( ccnt, prefixFolder = prefixFolder )
		
		if ( WaveExists( $wname ) == 1 )
			AppendToTable /W=$child $wname
			ModifyTable /W=$child width($wname)=100
		endif
	
	endfor
	
	return 0

End // NMGroupsPanelTable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelDefaults()

	Variable icnt
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	Variable numWaves = NumVarOrDefault( prefixFolder+"NumWaves", 0 )
	
	Variable numGroups = NMGroupsNumCount( prefixFolder = prefixFolder )
	Variable firstGroup = NMGroupsFirst( "", prefixFolder = prefixFolder )
	Variable fromWave = NumVarOrDefault( prefixFolder+"GroupsFromWave", Nan )
	Variable toWave = NumVarOrDefault( prefixFolder+"GroupsToWave", Nan )
	Variable blocks = NumVarOrDefault( prefixFolder+"GroupsWaveBlocks", Nan )
	
	String groupSeq = StrVarOrDefault( prefixFolder+"GroupsSeqStr", "" )
	
	if ( ( numtype( numGroups ) > 0 ) || ( numGroups < 1 ) )
		numGroups = NMGroupsNumDefault( prefixFolder = prefixFolder )
		groupSeq = ""
	endif
	
	if ( ( numtype( firstGroup ) > 0 ) || ( firstGroup < 0 ) )
		firstGroup = NMFirstGroup
		groupSeq = ""
	endif
	
	if ( ( numtype( fromWave ) > 0 ) || ( fromWave < 0 ) || ( fromWave >= numWaves ) )
		fromWave = 0
	endif
	
	if ( ( numtype( toWave ) > 0 ) || ( toWave < 0 ) || ( toWave >= numWaves ) )
		toWave = numWaves - 1
	endif
	
	if ( ( numtype( blocks ) > 0 ) || ( blocks < 1 ) )
		blocks = 1
	endif
	
	if ( strlen( groupSeq ) == 0 )
		groupSeq = num2istr( firstGroup ) + " - " + num2istr( firstGroup + numGroups - 1 )
		//group = RangeToSequenceStr( group )
	endif
	
	SetNMvar( prefixFolder+"NumGrps", numGroups )
	SetNMvar( prefixFolder+"FirstGrp", firstGroup )
	SetNMvar( prefixFolder+"GroupsFromWave", fromWave )
	SetNMvar( prefixFolder+"GroupsToWave", toWave )
	SetNMvar( prefixFolder+"GroupsWaveBlocks", blocks )
	
	SetNMstr( prefixFolder+"GroupsSeqStr", groupSeq )
	
	CheckNMvar( NMDF+"GroupsPanelAutoSave", 1 )

End // NMGroupsPanelDefaults

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )

	NMGroupsPanelFxnCall( fxn, varStr )
	
End // NMGroupsPanelSetVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMGroupsPanelFxnCall( fxn, "" )
	
End // NMGroupsPanelButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMGroupsPanelFxnCall( fxn, num2istr( checked ) )

End // NMGroupsPanelCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelHook( s )
	STRUCT WMWinHookStruct &s
	
	String prefixFolder = CurrentNMPrefixFolder()
	String pname = NMGroupsPanelName
	String tname = NMGroupsPanelName + "Table"
	
	Variable autoSave = NumVarOrDefault( NMDF+"GroupsPanelAutoSave", 1 )
	
	String win = s.winName
	Variable event = s.eventCode
	
	GetWindow $win activeSW
	
	String activeSubwindow = S_value
	
	if ( StringMatch( s.eventName, "kill" ) == 1 )
	
		if ( NumVarOrDefault( prefixFolder+"GroupsPanelChange", 0 ) == 1 )
		
			if ( autoSave == 1 )
			
				NMGroupsPanelSave()
			
			else
			
				DoAlert 1, "Save changes to your current Groups?"
			
				if ( V_flag == 1 )
					NMGroupsPanelSave()
				endif
			
			endif
			
		endif
		
		NMGroupsPanelTable( 0 )
		KillWaves /Z $NMGroupsWaveName( prefixFolder = prefixFolder )
		
		return 0
		
	endif
	
	if ( ( NumVarOrDefault( prefixFolder+"GroupsPanelChange", 0 ) == 1 ) && ( autoSave == 1 ) )
		NMGroupsPanelSave()
		return 0
	endif
	
	if ( strsearch( activeSubwindow, tname, 0, 2 ) > 0 )
	
		if ( ( StringMatch( s.eventName, "keyboard" ) == 1 ) && ( s.keycode == 13 ) ) // user hit "enter" in table
			SetNMvar( prefixFolder+"GroupsPanelChange", 1 )
		endif
		
	endif
	
	return 0

End // NMGroupsPanelHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelFxnCall( fxn, select )
	String fxn
	String select
	
	Variable snum = str2num( select )

	strswitch( fxn )
		
		case "NumGroups":
			return NMGroupsPanelSeqUpdate()
			
		case "FirstGroup":
			return NMGroupsPanelSeqUpdate()
	
		case "WaveStart":
		case "WaveEnd":
		case "WaveBlocks":
			return 0
		
		case "SeqStr":
			return NMGroupsPanelSeqSet()
			
		case "Execute":
			return NMGroupsPanelExecute()
			
		case "Clear":
			return NMGroupsPanelClear()
			
		case "Close":
			return NMGroupsPanelClose()
			
		case "Save":
			return NMGroupsPanelSave()
			
		case "SaveAuto":
			return NMGroupsPanelSaveAutoToggle()
			
		default:
			NMDoAlert( "NMGroupsPanelFxnCall: unrecognized function call: " + fxn )
			return -1
			
	endswitch
	
	return 0
	
End // NMGroupsPanelFxnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSeqSet()

	Variable gcnt, group, numGroups, firstGroup

	String prefixFolder = CurrentNMPrefixFolder()
	
	String groupSeq = StrVarOrDefault( prefixFolder+"GroupsSeqStr", "" )
	
	if ( ( strsearch( groupSeq, "-", 0 ) > 0 ) || ( strsearch( groupSeq, ",", 0 ) > 0 ) )
		groupSeq = RangeToSequenceStr( groupSeq )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numGroups = ItemsInList( groupSeq )
	
	firstGroup = NMGroupsFirst( groupSeq, prefixFolder = prefixFolder )
	
	if ( numGroups == 0 )
	
		return NMGroupsPanelSeqUpdate()
		
	else
	
		SetNMvar( prefixFolder+"NumGrps", numGroups )
		SetNMvar( prefixFolder+"FirstGrp", firstGroup )
		
	endif
	
	return 0

End // NMGroupsPanelSeqSet()

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSeqUpdate()

	String groupSeq
	String prefixFolder = CurrentNMPrefixFolder()

	Variable numGroups = NumVarOrDefault( prefixFolder+"NumGrps", Nan )
	Variable firstGroup = NumVarOrDefault( prefixFolder+"FirstGrp", NMFirstGroup )
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( numtype( numGroups * firstGroup ) > 0 ) )
		return -1
	endif
	
	groupSeq = num2istr( firstGroup ) + " - " + num2istr( firstGroup + numGroups - 1 )
	
	//groupSeq = RangeToSequenceStr( groupSeq )
	
	SetNMstr( prefixFolder+"GroupsSeqStr", groupSeq )
	
	return 0

End // NMGroupsPanelSeqUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelExecute()

	String prefixFolder = CurrentNMPrefixFolder()
	String gwName = NMGroupsWaveName( prefixFolder = prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	Variable numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	Variable fromWave = NumVarOrDefault( prefixFolder+"GroupsFromWave", 0 )
	Variable toWave = NumVarOrDefault( prefixFolder+"GroupsToWave", numWaves - 1 )
	Variable blocks = NumVarOrDefault( prefixFolder+"GroupsWaveBlocks", 1 )
	
	String groupSeq = StrVarOrDefault( prefixFolder+"GroupsSeqStr", "" )
	
	if ( ( ItemsInList( groupSeq ) > 0 ) && ( WaveExists( $gwName ) == 1 ) )
		WaveSequence( gwName, groupSeq, fromWave, toWave, blocks )
	endif
	
	SetNMvar( prefixFolder+"GroupsPanelChange", 1 )
	
	return 0

End // NMGroupsPanelExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelClear()

	String prefixFolder = CurrentNMPrefixFolder()
	String gwName = NMGroupsWaveName( prefixFolder = prefixFolder )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( WaveExists( $gwName ) == 1 )
	
		Wave wtemp = $gwName
		
		wtemp = Nan
		
		SetNMvar( prefixFolder+"GroupsPanelChange", 1 )
		
		return 0
		
	endif
	
	return -1

End // NMGroupsPanelClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelClose()

	String prefixFolder = CurrentNMPrefixFolder()

	DoWindow /K $NMGroupsPanelName
	KillWaves /Z $NMGroupsWaveName( prefixFolder = prefixFolder )
	
	KillVariables /Z $prefixFolder+"GroupsPanelChange"

End // NMGroupsPanelClose

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSave()

	String gwName
	String prefixFolder = CurrentNMPrefixFolder()

	if ( NumVarOrDefault( prefixFolder+"GroupsPanelChange", 0 ) == 0 )
		return 0 // nothing to do
	endif
	
	gwName = NMGroupsWaveName( prefixFolder = prefixFolder )
	
	NMGroupsWaveToLists( gwName, prefixFolder = prefixFolder )
	UpdateNMGroups( prefixFolder = prefixFolder )
	
	SetNMvar( prefixFolder+"GroupsPanelChange", 0 )

End // NMGroupsPanelSave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupsPanelSaveAutoToggle()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	Variable on = NumVarOrDefault( NMDF+"GroupsPanelAutoSave", 1 )
	
	on = BinaryInvert( on )
	
	SetNMvar( NMDF+"GroupsPanelAutoSave", on )
	
	NMGroupsPanelUpdate( 1 )
	
	return on
	
End // NMGroupsPanelSaveAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function NMGroupFilter( n, group ) // NOT USED
	Variable n
	Variable group

	if ( ( group == -1 ) && ( numtype( n ) == 0 ) )
		return 1 // All Groups
	elseif ( n == group )
		return 1
	else
		return 0
	endif
	
End // NMGroupFilter

//****************************************************************
//****************************************************************
//****************************************************************