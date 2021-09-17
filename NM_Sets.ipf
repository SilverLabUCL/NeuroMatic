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
//	Sets Functions
//
//	Set and Get functions:
//
//		NMSetsSet( [ setList, value, waveNum, fromWave, toWave, skipWaves, clearFirst, conversionWave, equation, equationLocked, setXclude, autoWaveAdvance, displayList, prefixFolder, update, history ] )
//
//	Useful Functions:
//
//		NMSetsNew( setList [ prefixFolder, update, history ] )
//		NMSetsClear( setList [ prefixFolder, clearEqLock, update, history ] )
//		NMSetsKill( setList [ prefixFolder, update, history ] )
//		NMSetsCopy( setName, newName [ prefixFolder, update, history ] )
//		NMSetsRename( setName, newName [ prefixFolder, update, history ] )
//		NMSetsInvert( setList [ prefixFolder, update, history ] )
//		NMSetsEqLockTableEdit( [ prefixFolder, history ] )
//		NMSetsEqLockTablePrint( [ prefixFolder, history ] )
//		NMSetsPanel( [ history ] )
//
//****************************************************************
//****************************************************************
//****************************************************************

StrConstant NMSetsPanelName = "NM_SetsPanel"
StrConstant NMSetsListDefault = "Set1;Set2;SetX;"
StrConstant NMSetsListSuffix = "_SetList"

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsOK()

	if ( strlen( CurrentNMPrefixFolder() ) > 0 )
		return 1
	endif
	
	NMDoAlert( "No Sets. You may need to select " + NMQuotes( "Wave Prefix" ) + " first." )
	
	return 0

End // NMSetsOK

//****************************************************************
//****************************************************************

//Function NMSetsSet( setName, waveNum, value ) // OLD FUNCTION HAS BEEN OVERWRITTEN
//	String setName
//	Variable waveNum
//	Variable value
	
//	NMDeprecatedAlert( "NMSetsAssign" )
	
//	return NMSetsAssign( setName, waveNum, value )
	
//End // NMSetsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsSet( [ setList, value, waveNum, fromWave, toWave, skipWaves, clearFirst, conversionWave, equation, equationLocked, setXclude, autoWaveAdvance, displayList, prefixFolder, update, history ] )

	String setList // list of Sets, or "All"
	Variable value // ( 0 ) remove from Set ( 1 ) add to Set
	Variable waveNum // wave number, or specify fromWave and toWave below
	Variable fromWave // from wave number ( use with setList and value )
	Variable toWave // to wave number
	Variable skipWaves // skip wave increment ( 0 ) to include all waves between fromWave and toWave
	Variable clearFirst // clear set before executing ( 0 ) no ( 1 ) yes
	
	String conversionWave // wave of 1s and 0s (use with setList)
	
	String equation // e.g. Set1 = Set2 AND Set3
	String equationLocked // e.g. Set1 = Set2 AND Set3 (equation is locked)
	
	Variable autoWaveAdvance // advance to next wave after executing ( 0 ) no ( 1 ) yes
	
	Variable setXclude // SetX is excluding ( 0 ) no ( 1 ) yes
	String displayList // 3 Sets to display on NM Panel
	
	String prefixFolder // full-path prefix subfolder
	
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable goToNextWave, updateNM
	String setName, arg1, operation, arg2, vlist = "", vlist2 = ""
	
	if ( ParamIsDefault( update ) )
		update = 1
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
	
	if ( !ParamIsDefault( autoWaveAdvance ) )
	
		vlist = NMCmdNumOptional( "autoWaveAdvance", autoWaveAdvance, vlist, integer = 1 )
		
		SetNMvar( NMDF+"SetsAutoAdvance", BinaryCheck( autoWaveAdvance ) )
		
	endif
	
	if ( !ParamIsDefault( setXclude ) )
	
		vlist = NMCmdNumOptional( "setXclude", setXclude, vlist, integer = 1 )
		
		NMSetXclude( BinaryCheck( setXclude ), prefixFolder = prefixFolder )
		
	endif
	
	if ( !ParamIsDefault( displayList ) )
	
		vlist = NMCmdStrOptional( "displayList", displayList, vlist )
		
		NMSetsDisplaySet( displayList, prefixFolder = prefixFolder )
		
	endif
	
	if ( !ParamIsDefault( setList ) )
	
		vlist = NMCmdStrOptional( "setList", setList, "" )
	
		if ( !ParamIsDefault( waveNum ) && !ParamIsDefault( value ) )
		
			vlist = NMCmdNumOptional( "value", value, vlist )
			vlist = NMCmdNumOptional( "waveNum", waveNum, vlist, integer = 1 )
		
			fromWave = waveNum
			toWave = waveNum
			skipWaves = 0
			clearFirst = 0
			goToNextWave = NMVarGet( "SetsAutoAdvance" )
			
			NMSetsDefine( setList, value, fromWave, toWave, skipWaves, clearFirst, prefixFolder = prefixFolder, update = 0, goToNextWave = goToNextWave )
			updateNM = 1
			
		elseif ( !ParamIsDefault( conversionWave ) )
		
			vlist = NMCmdStrOptional( "conversionWave", conversionWave, vlist )
		
			NMSetsConvert( conversionWave, setList, prefixFolder = prefixFolder, update = 0 )
			updateNM = 1
			
		elseif ( !ParamIsDefault( value ) )
		
			vlist = NMCmdNumOptional( "value", value, vlist )
		
			if ( ParamIsDefault( fromWave ) )
				fromWave = 0
			else
				vlist = NMCmdNumOptional( "fromWave", fromWave, vlist, integer = 1 )
			endif
			
			if ( ParamIsDefault( toWave ) )
				toWave = inf
			else
				vlist = NMCmdNumOptional( "toWave", toWave, vlist, integer = 1 )
			endif
			
			if ( ParamIsDefault( skipWaves ) )
				skipWaves = 0
			else
				vlist = NMCmdNumOptional( "skipWaves", skipWaves, vlist, integer = 1 )
			endif
			
			if ( ParamIsDefault( clearFirst ) )
				clearFirst = 0
			else
				vlist = NMCmdNumOptional( "clearFirst", clearFirst, vlist, integer = 1 )
			endif
			
			goToNextWave = 0
			
			NMSetsDefine( setList, value, fromWave, toWave, skipWaves, clearFirst, prefixFolder = prefixFolder, update = 0, goToNextWave = goToNextWave )
			updateNM = 1
		
		endif
		
	endif
	
	if ( !ParamIsDefault( equation ) )
	
		vlist = NMCmdStrOptional( "equation", equation, vlist )
	
		setName = NMSetsEquationParse( equation, "set" )
		arg1 = NMSetsEquationParse( equation, "arg1" )
		operation = NMSetsEquationParse( equation, "op" )
		arg2 = NMSetsEquationParse( equation, "arg2" )
	
		NMSetsEquation( setName, arg1, operation, arg2, prefixFolder = prefixFolder, update = 0 )
		
		updateNM = 1
		
	endif
	
	if ( !ParamIsDefault( equationLocked ) )
	
		vlist = NMCmdStrOptional( "equationLocked", equationLocked, vlist )
	
		setName = NMSetsEquationParse( equationLocked, "set" )
		arg1 = NMSetsEquationParse( equationLocked, "arg1" )
		operation = NMSetsEquationParse( equationLocked, "op" )
		arg2 = NMSetsEquationParse( equationLocked, "arg2" )
	
		NMSetsEquationLock( setName, arg1, operation, arg2, prefixFolder = prefixFolder, update = 0 )
		
		updateNM = 1
	
	endif
	
	if ( history )
		NMCommandHistory( vlist + vlist2 )
	endif
	
	if ( update && updateNM )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif

End // NMSetsSet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAutoAdvanceCall( on ) // auto advance wave increment
	Variable on
	
	if ( ( on != 0 ) && ( on != 1 ) )
	
		on = 1 + NMVarGet( "SetsAutoAdvance" )
	
		Prompt on, "auto-advance wave number after each checkbox selection?", popup "no;yes;"
		DoPrompt "Sets Auto Wave Advance", on
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		on -= 1
		
	endif
	
	return NMSetsSet( autoWaveAdvance = on, history = 1 )
	
End // NMSetsAutoAdvanceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSets( [ prefixFolder ] )
	String prefixFolder

	Variable scnt
	String setList, setName, setDataList = ""

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	setList = NMSetsWavesList( prefixFolder, 0 )
	
	if ( ItemsInList( setList ) > 0 )
	
		for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
		
			setName = StringFromList( scnt, setList )
			
			if ( StringMatch( setName[0,7], "Set_Data" ) )
				setDataList = AddListItem( setName, setDataList, ";", inf )
			endif
			
		endfor
		
		if ( ItemsInList( setDataList ) == 1 )
		
			setName = StringFromList( 0, setDataList )
			
			if ( StringMatch( setName, "Set_Data0" ) )
				
				Wave wtemp = $prefixFolder+setName
				
				if ( sum( wtemp ) == numpnts( wtemp ) )
					KillWaves /Z $prefixFolder+setName // this wave is unecessary
					setList = RemoveFromList( setName, setList )
				endif
				
			endif
			
		endif
	
		OldNMSetsWavesToLists( setList, prefixFolder = prefixFolder )
		
	endif
	
	CheckNMSetsExist( NMSetsListDefault, prefixFolder = prefixFolder )

	return 0

End // CheckNMSets

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsCall( fxn, select )
	String fxn, select
	
	Variable snum = str2num( select )
	
	if ( !NMSetsOK() )
		return -1
	endif
	
	strswitch( fxn )
	
		case "Define":
			return NMSetsDefineCall()
		
		case "Equation":
		case "Function":
			return NMSetsEquationCall()
			
		case "Edit Panel":
			return NMSetsPanel( history = 1 )
			
		case "Edit Equations":
			return NMSetsEqLockTableEdit( history = 1 )
			
		case "Print Equations":
			return NMSetsEqLockTablePrint( history = 1 )
			
		case "Convert":
			return NMSetsConvertCall()
			
		case "Invert":
			return NMSetsInvertCall( "" )
			
		case "Clear":
			return NMSetsClearCall( "" )
			
		case "New":
			return NMReturnStr2Num( NMSetsNewCall( "" ) )
			
		case "New via String Key":
			return NMReturnStr2Num( NMSetsNewByStringKeyCall() )
			
		case "Copy":
			return NMReturnStr2Num( NMSetsCopyCall( "" ) )
			
		case "Rename":
			return NMReturnStr2Num( NMSetsRenameCall( "" ) )
			
		case "Kill":
			return NMSetsKillCall( "" )
		
		case "Set0Check":
			return NMSetsAssignCall( NMSetsDisplayName( 0 ), snum )

		case "Set1Check":
			return NMSetsAssignCall( NMSetsDisplayName( 1 ), snum )

		case "Set2Check":
			return NMSetsAssignCall( NMSetsDisplayName( 2 ), snum )
			
		case "Exclude SetX?":
			return NMSetXCall( Nan )
			
		case "Auto Advance":
			return NMSetsAutoAdvanceCall( Nan )
			
		case "Display":
		case "SetsDisplay":
			return NMSetsDisplayCall()
			
		default:
			NMDoAlert( "NMSetsCall: unrecognized function call: " + fxn )
			
	endswitch
	
	return -1

End // NMSetsCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsStrVarPrefix( setName )
	String setName
	
	Variable numCharSuffix = strlen( NMSetsListSuffix ) + 1 // extra for chan character
	
	setName = setName[ 0, 30 - numCharSuffix ] // there is 31 char limit
	
	setName += NMSetsListSuffix
	
	setName = NMCheckStringName( setName )
	
	return setName
	
End // NMSetsStrVarPrefix

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsStrVarName( setName, chanNum [ prefixFolder ] )
	String setName
	Variable chanNum
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	return prefixFolder + NMSetsStrVarPrefix( setName ) + ChanNum2Char( chanNum )

End // NMSetsStrVarName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNameGet( strVarName )
	String strVarName // e.g. "TTX_SetWaveListA"
	
	Variable icnt = strsearch( strVarName, NMSetsListSuffix, 0, 2 )
		
	if ( icnt <= 0 )
		return ""
	endif
		
	return strVarName[ 0, icnt - 1 ] // e.g. "TTX"
	
End // NMSetsNameGet

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsStrVarSearch( setName, fullPath [ prefixFolder ] )
	String setName
	Variable fullPath
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	String setsPrefix = NMSetsStrVarPrefix( setName )

	return NMFolderStringList( prefixFolder, setsPrefix + "*", ";", fullPath )
	
End // NMSetsStrVarSearch

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsWaveListAll( [ prefixFolder ] )
	String prefixFolder

	Variable scnt, chanNum = 0
	String setList, setName, wList = ""

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
		
		wList += NMSetsWaveList( setName, chanNum, prefixFolder = prefixFolder )
		
	endfor

	return wList

End // NMSetsWaveListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsWaveList( setName, chanNum [ prefixFolder ] )
	String setName
	Variable chanNum
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	String strVarName = NMSetsStrVarName( setName, chanNum, prefixFolder = prefixFolder )
	
	if ( strlen( strVarName ) == 0 )
		return ""
	endif
	
	return StrVarOrDefault( strVarName, "" )
	
End // NMSetsWaveList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsWaveListAdd( waveListToAdd, setName, chanNum [ prefixFolder ] )
	String waveListToAdd
	String setName
	Variable chanNum
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	String strVarName = NMSetsStrVarName( setName, chanNum, prefixFolder = prefixFolder )
	
	return NMPrefixFolderStrVarListAdd( waveListToAdd, strVarName, chanNum, prefixFolder = prefixFolder )
	
End // NMSetsWaveListAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsWaveListRemove( waveListToRemove, setName, chanNum [ prefixFolder ] )
	String waveListToRemove
	String setName
	Variable chanNum
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	String strVarName = NMSetsStrVarName( setName, chanNum, prefixFolder = prefixFolder )
	
	return NMPrefixFolderStrVarListRemove( waveListToRemove, strVarName, chanNum )
	
End // NMSetsWaveListRemove

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsListAll( [ prefixFolder ] ) // all sets + all groups
	String prefixFolder
	
	Variable scnt
	String matchStr, setName, strVarName, strVarList, outList = ""
	
	String defaultList = NMSetsListDefault
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( defaultList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, defaultList )
		
		if ( ( strlen( setName ) > 0 ) && AreNMSets( setName, prefixFolder = prefixFolder ) )
			outList += setName + ";"
		endif
		
	endfor
	
	matchStr = "*" + NMSetsListSuffix + "*"
	
	strVarList = NMFolderStringList( prefixFolder, matchStr, ";", 0 )
	
	for ( scnt = 0 ; scnt < ItemsInList( strVarList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, strVarList )
		setName = NMSetsNameGet( setName )
		
		if ( strlen( setName ) > 0 )
			outList = NMAddToList( setName, outList, ";" )
		endif
		
	endfor
	
	return outList

End // NMSetsListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsList( [ prefixFolder ] )
	String prefixFolder

	Variable scnt
	String setName, allList, setList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	allList = NMSetsListAll( prefixFolder = prefixFolder )
	
	for ( scnt = 0 ; scnt< ItemsInList( allList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, allList )
		
		if ( !StringMatch( setName[0,4], "Group" ) ) // remove Groups
			setList = AddlistItem( setName, setList, ";", inf )
		endif
		
	endfor
	
	if ( ( NMSetXType( prefixFolder = prefixFolder ) == 1 ) && ( WhichListItem( "SetX", setList ) > 1 ) )
		setList = RemoveFromList( "SetX", setList )
		setList = AddListItem( "SetX", setList, ";", inf ) // place SetX at end of list
	endif
	
	return setList

End // NMSetsList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsListXclude( [ prefixFolder ] )
	String prefixFolder
	
	String setList

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	setList = NMSetsList( prefixFolder = prefixFolder )
	
	if ( NMSetXType( prefixFolder = prefixFolder ) == 1 )
		return RemoveFromList( "SetX", setList )
	endif
	
	return setList

End // NMSetsListXclude

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsListCheck( fxnName, setList, alert [ prefixFolder ] )
	String fxnName // calling function name for alert
	String setList // list to check
	Variable alert // ( 0 ) no ( 1 ) yes
	String prefixFolder
	
	Variable scnt
	String setName, badList = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( ItemsInList( NMSetsStrVarSearch( setName, 0, prefixFolder = prefixFolder ) ) == 0 )
			badList += setName + ";" 
		endif
		
	endfor
	
	if ( alert && ( ItemsInList( badList ) > 0 ) )
		NMDoAlert( fxnName + " Error: the following set(s) do not exist: " + badList )
	endif
	
	return badList

End // NMSetsListCheck

//****************************************************************
//****************************************************************
//****************************************************************

Function AreNMSets( setList [ prefixFolder ] )
	String setList
	String prefixFolder
	
	Variable scnt
	String setName, setList2
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		setList2 = NMSetsStrVarSearch( setName, 0, prefixFolder = prefixFolder )
		
		if ( ItemsInList( setList2 ) == 0 )
			return 0
		endif
		
	endfor
	
	return 1
	
End // AreNMSets

//****************************************************************
//****************************************************************
//****************************************************************

Function CheckNMSetsExist( setList [ prefixFolder ] )
	String setList
	String prefixFolder

	Variable scnt
	String setName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( !AreNMSets( setName, prefixFolder = prefixFolder ) )
			NMSetsNew( setName, prefixFolder = prefixFolder, update = 0 )
		endif
		
	endfor
	
	return 0

End // CheckNMSetsExist

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNameNext( [ prefixFolder ] )
	String prefixFolder

	Variable icnt
	String setName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	for ( icnt = 1; icnt < 99; icnt += 1 )
	
		setName = "Set" + num2istr( icnt )
		
		if ( !AreNMSets( setName, prefixFolder = prefixFolder ) )
			return setName
		endif
		
	endfor

	return ""
	
End // NMSetsNameNext

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsNumNext( [ prefixFolder ] )
	String prefixFolder

	Variable icnt
	String setName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	for ( icnt = 1; icnt < 99; icnt += 1 )
	
		setName = "Set" + num2istr( icnt )
		
		if ( !AreNMSets( setName, prefixFolder = prefixFolder ) )
			return icnt
		endif
		
	endfor

	return NaN
	
End // NMSetsNumNext

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMSetsDefault( setName )
	String setName
	
	if ( WhichListItem( setName, NMSetsListDefault ) >= 0 )
		return 1
	endif
	
	return 0
	
End // IsNMSetsDefault

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMSetsItem( setName, chanNum, wName [ prefixFolder ] )
	String setName
	Variable chanNum
	String wName
	String prefixFolder
	
	Variable waveNum
	String wList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	if ( chanNum < 0 )
		chanNum = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	endif
	
	if ( strlen( wName ) == 0 )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
		wName = NMChanWaveName( chanNum, waveNum, prefixFolder = prefixFolder )
	endif
	
	wList = NMSetsWaveList( setName, chanNum, prefixFolder = prefixFolder )
	
	if ( WhichListItem( wName, wList ) >= 0 )
		return 1
	endif
	
	return 0

End // IsNMSetsItem

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNewNameAsk()

	String setName = NMSetsNameNext()
	
	Prompt setName, "enter new set name:"
	DoPrompt "New Sets", setName

	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return setName
	
End // NMSetsNewNameAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNewCall( setName )
	String setName
	
	if ( strlen( setName ) == 0 )
		setName = NMSetsNewNameAsk()
	endif
	
	if ( strlen( setName ) == 0 )
		return "" // cancel
	endif
	
	return NMSetsNew( setName, history = 1 )

End // NMSetsNewCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNew( setList [ prefixFolder, update, history ] )
	String setList
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable scnt, ccnt, numChannels
	String setName, strVarName, strVarList, setList2 = ""
	
	String vlist = NMCmdStr( setList, "" )
	
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
		return ""
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		setName = NMCheckStringName( setName )
		
		if ( exists( setName ) >= 3 )
			return NM2ErrorStr( 24, "setName", setName )
		endif
		
		if ( AreNMSets( setName, prefixFolder = prefixFolder ) )
			continue // already exists
		endif
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			strVarName = NMSetsStrVarName( setName, ccnt, prefixFolder = prefixFolder )
			
			SetNMstr( strVarName, "" )
		
		endfor
		
		setList2 = AddListItem( setName, setList2, ";", inf )
		
	endfor
	
	if ( update )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	return setList2
	
End // NMSetsNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNewByStringKeyCall()
	
	String prefixFolder = CurrentNMPrefixFolder()
	String pTitle = "Create new sets via a wave-name key"
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	String stringKey = StrVarOrDefault( prefixFolder+"StringKey", "" )
	Variable keySeq = NumVarOrDefault( prefixFolder+"KeySeq", 0 )
	Variable setPrefixSameAsStringKey = NumVarOrDefault( prefixFolder+"SetPrefixSameAsStringKey", 1 )
	String setPrefix = StrVarOrDefault( prefixFolder+"SetPrefix", "" )
	
	keySeq += 1
	setPrefixSameAsStringKey += 1
	
	Prompt stringKey, "enter wave-name string key (e.g. \"ROI\")"
	Prompt keySeq, "search for sequence number(s) following string key?", popup "no;yes;"
	Prompt setPrefixSameAsStringKey, "use string key as the new set name?", popup "no;yes;"
	DoPrompt pTitle, stringKey, keySeq, setPrefixSameAsStringKey
		
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	keySeq -= 1
	setPrefixSameAsStringKey -= 1
	
	SetNMstr( prefixFolder+"StringKey", stringKey )
	SetNMvar( prefixFolder+"KeySeq", keySeq )
	SetNMvar( prefixFolder+"SetPrefixSameAsStringKey", setPrefixSameAsStringKey )
	
	if ( setPrefixSameAsStringKey )
	
		setPrefix = stringKey
		
	else
	
		Prompt setPrefix, "enter set name prefix"
		DoPrompt pTitle, setPrefix
		
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		SetNMstr( prefixFolder+"SetPrefix", setPrefix )
	
	endif
	
	return NMSetsNewByStringKey( stringKey, keySeq, setPrefix, prefixFolder = prefixFolder, history = 1 )

End // NMSetsNewByStringKeyCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsNewByStringKey( stringKey, keySeq, setPrefix [ prefixFolder, update, history ] )
	String stringKey
	Variable keySeq // look for string-key sequence ( 0 ) no ( 1 ) yes
	String setPrefix
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable numChannels, numWaves, ccnt, wcnt, wcnt2, ibgn, iend, jbgn, jend, jcnt
	String waveSelectList, waveSelectList2, wName, wName2, setName, strVarName, seqStr
	String wList, vlist = "", setList2 = ""
	
	vlist = NMCmdStr( stringKey, vlist )
	vlist = NMCmdNum( keySeq, vlist )
	vlist = NMCmdStr( setPrefix, vlist )
	
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
		return ""
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	waveSelectList = NMChanWaveList( 0 )
		
	numWaves = ItemsInList( waveSelectList )
	
	if ( numWaves == 0 )
		return ""
	endif
		
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		wName = StringFromList( wcnt, waveSelectList )
		ibgn = strsearch( wName, stringKey, 0 )
		
		if ( ibgn < 0 )
			continue
		endif
		
		iend = ibgn + strlen( stringKey ) - 1
		
		if ( keySeq )
		
			jbgn = iend + 1
			jend = strlen( wName ) - 1
			
			for ( jcnt = jbgn ; jcnt < strlen( wName ) ; jcnt += 1 )
				if ( numtype( str2num( wName[ jcnt ] ) ) == 2 )
					jend = jcnt - 1
					break // found end of sequence number
				endif
			endfor
			
			seqStr = wName[ jbgn, jend ]
			
		else
		
			seqStr = ""
			
		endif
		
		setName = setPrefix + seqStr
		
		setName = NMCheckStringName( setName )
	
		if ( exists( setName ) >= 3 )
			return NM2ErrorStr( 24, "setName", setName )
		endif
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			waveSelectList2 = NMChanWaveList( ccnt )
			wList = ""
			
			for ( wcnt2 = 0 ; wcnt2 < ItemsInList( waveSelectList2 ) ; wcnt2 += 1 )
	
				wName2 = StringFromList( wcnt2, waveSelectList2 )
				
				if ( strsearch( wName2, stringKey + seqStr, 0 ) >= 0 )
					wList += wName2 + ";"
				endif
		
			endfor
	
			strVarName = NMSetsStrVarName( setName, ccnt, prefixFolder = prefixFolder )
		
			SetNMstr( strVarName, wList )
	
		endfor
	
		setList2 = AddListItem( setName, setList2, ";", inf )
		
	endfor
	
	if ( update )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	return setList2
	
End // NMSetsNewByStringKey

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsClearCall( setName )
	String setName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( strlen( setName ) == 0 )

		Prompt setName, " ", popup NMSetsList()
		DoPrompt "Clear Sets", setName
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
	endif
	
	return NMSetsClear( setName, prefixFolder = prefixFolder, history = 1 )

End // NMSetsClearCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsClear( setList [ prefixFolder, clearEqLock, update, history ] )
	String setList // set name list, or "All"
	String prefixFolder
	Variable clearEqLock
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable scnt, icnt
	String setName, strVarList, eList
	
	String vlist = NMCmdStr( setList, "" )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( ParamIsDefault( clearEqLock ) )
		clearEqLock = 1
	else
		vlist = NMCmdNumOptional( "clearEqLock", clearEqLock, vlist, integer = 1 )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( StringMatch( setList, "All" ) )
		setList = NMSetsList()
	endif
	
	if ( clearEqLock )
		NMSetsEqLockTableClear( setList, prefixFolder = prefixFolder )
	endif
	
	eList = NMSetsListCheck( "NMSetsClear", setList, 1, prefixFolder = prefixFolder )
	
	if ( ItemsInList( eList ) > 0 )
		return -1
	endif
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		strVarList = NMSetsStrVarSearch( setName, 1, prefixFolder = prefixFolder )
		
		for ( icnt = 0 ; icnt < ItemsInList( strVarList ) ; icnt += 1 ) 
			SetNMstr( StringFromList( icnt, strVarList ) , "" )
		endfor
	
	endfor
		
	if ( update )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	return 0
	
End // NMSetsClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsKillCall( setName )
	String setName

	String wlist
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( strlen( setName ) == 0 )
	
		wlist = NMSetsList()
		
		if ( ItemsInlist( wlist ) == 0 )
			NMDoAlert( "No Sets to kill!")
			return -1
		endif
		
		wlist = " ;" + wlist
	
		Prompt setName, "select Set to kill:", popup wlist
		DoPrompt "Kill Sets", setName
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
	endif
	
	return NMSetsKill( setName, prefixFolder = prefixFolder, history = 1 )

End // NMSetsKillCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsKill( setList [ prefixFolder, update, history ] )
	String setList // set name list, or "All"
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable scnt, killedsomething
	String setName
	
	String vlist = NMCmdStr( setList, "" )
	
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
	
	if ( StringMatch( setList, "All" ) )
		setList = NMSetsList()
	endif
	
	NMSetsEqLockTableClear( setList, prefixFolder = prefixFolder )
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
		setName = StringFromList( scnt, setList )
		killedsomething += NMPrefixFolderStrVarKill( NMSetsStrVarPrefix( setName ), prefixFolder = prefixFolder )
	endfor
	
	if ( update )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	return 0
	
End // NMSetsKill

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsCopyCall( setName )
	String setName
	
	Variable icnt
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	String newName = NMSetsNameNext()
	
	Prompt setName, "select Set to copy:", popup NMSetsList()
	Prompt newName, "enter new set name:"
	
	if ( strlen( setName ) > 0 )
		DoPrompt "Copy Sets", newName
	else
		DoPrompt "Copy Sets", setName, newName
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return NMSetsCopy( setName, newName, prefixFolder = prefixFolder, history = 1 )

End // NMSetsCopyCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsCopy( setName, newName [ prefixFolder, update, history ] )
	String setName, newName
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable vcnt
	String strVarName, strVarList, strVarNameNew, wList, vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	vlist = NMCmdStr( setName, vlist )
	vlist = NMCmdStr( newName, vlist )
	
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
		return ""
	endif
	
	if ( StringMatch( setName, newName ) )
		return "" // nothing to do
	endif
	
	if ( !AreNMSets( setName, prefixFolder = prefixFolder ) )
		NMDoAlert( thisfxn + " Abort: " + setName + " is not a Set." )
		return ""
	endif
	
	if ( AreNMSets( newName, prefixFolder = prefixFolder ) )
	
		DoAlert 1, "Copy Alert: " + newName + " already exists. Do you want to overwrite it?"
		
		if ( V_Flag != 1 )
			return "" // cancel
		endif
		
		strVarList = NMSetsStrVarSearch( setName, 1, prefixFolder = prefixFolder )
	
		for ( vcnt = 0 ; vcnt < ItemsInList( strVarList ) ; vcnt += 1 )
			KillStrings /Z $StringFromList( vcnt, strVarList )
		endfor
		
	endif
	
	strVarList = NMSetsStrVarSearch( setName, 0, prefixFolder = prefixFolder )
	
	for ( vcnt = 0 ; vcnt < ItemsInList( strVarList ) ; vcnt += 1 )
	
		strVarName = StringFromList( vcnt, strVarList )
		strVarNameNew = ReplaceString( setName, strVarName, newName )
		wList = StrVarOrDefault( prefixFolder+strVarName, "" )
		
		SetNMstr( prefixFolder+strVarNameNew, wList )

	endfor
	
	if ( update )
		UpdateNMPanelWaveSelect()
	endif
	
	return newName
	
End // NMSetsCopy

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsRenameCall( setName )
	String setName
	
	Variable icnt
	String vlist = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	String newName = NMSetsNameNext()
	String wlist = NMSetsList()
	
	wlist = RemoveFromList( NMSetsListDefault, wlist, ";" )
	wlist = RemoveFromList( NMSetsDisplayList(), wlist )
	
	if ( ItemsInList( wlist ) == 0 )
		NMDoAlert( "No Sets to rename." )
		return ""
	endif
	
	Prompt setName, "select wave to rename:", popup wlist
	Prompt newName, "enter new set name:"
	
	if ( strlen( setName ) > 0 )
		DoPrompt "Rename Sets", newName
	else
		DoPrompt "Rename Sets", setName, newName
	endif
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( IsNMSetLockedAlert( setName ) < 0 )
		UpdateNMPanelSets( 1 )
		return ""
	endif
	
	return NMSetsRename( setName, newName, prefixFolder = prefixFolder, history = 1 )

End // NMSetsRenameCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsRename( setName, newName [ prefixFolder, update, history ] )
	String setName
	String newName
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = "", thisfxn = GetRTStackInfo( 1 )
	
	vlist = NMCmdStr( setName, vlist )
	vlist = NMCmdStr( newName, vlist )
	
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
		return ""
	endif
	
	if ( IsNMSetLocked( setName, prefixFolder = prefixFolder ) )
		NMDoAlert( thisfxn + " Abort: " + setName + " is locked with an equation." )
		return ""
	endif
	
	if ( !AreNMSets( setName, prefixFolder = prefixFolder ) )
		NMDoAlert( thisfxn + " Abort: " + setName + " is not a Set." )
		return ""
	endif
	
	if ( IsNMSetsDefault( setName ) )
		NMDoAlert( thisfxn + " Abort: " + setName + " is a default Set and cannot be renamed." )
		return ""
	endif
	
	if ( IsNMSetsDisplay( setName, prefixFolder = prefixFolder ) )
		NMDoAlert( thisfxn + " Abort: " + setName + " is a display Set and cannot be renamed." )
		return ""
	endif
	
	if ( AreNMSets( newName, prefixFolder = prefixFolder ) )
		NMDoAlert( thisfxn + " Abort: " + newName + " already exists." )
		return ""
	endif
	
	NMSetsCopy( setName, newName, prefixFolder = prefixFolder, update = 0 )
	
	if ( AreNMSets( newName, prefixFolder = prefixFolder ) )
		NMSetsKill( setName, prefixFolder = prefixFolder, update = 0 )
	endif
	
	if ( update )
		UpdateNMPanelWaveSelect()
	endif
	
	return newName
	
End // NMSetsRename

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDefineCall( [ prefixFolder ] )
	String prefixFolder
	
	Variable wlimit, numWaves
	String vlist = ""
	
	String setList = NMSetsList()
	
	setList = NMAddToList( NMSetsListDefault, setList, ";" )
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	wlimit = numWaves - 1
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	Variable fromWave = NumVarOrDefault( prefixFolder+"SetsFromWave", 0 )
	Variable toWave = NumVarOrDefault( prefixFolder+"SetsToWave", wlimit )
	Variable skipWaves = NumVarOrDefault( prefixFolder+"SetsSkipWaves", 0 )
	Variable value = 1 //+ NumVarOrDefault( prefixFolder+"SetsDefineValue", 1 )
	Variable clearFirst = 1 + NumVarOrDefault( prefixFolder+"SetsDefineClear", 1 )
	
	Prompt setName, " ", popup setList
	Prompt fromWave, "FROM wave:"
	Prompt toWave, "TO wave:"
	Prompt skipWaves, "SKIP every other:"
	//Prompt value, "Define as:", popup "0;1;"
	Prompt clearFirst, "clear Set first?", popup "no;yes"
	
	//DoPrompt "Define Sets", setName, value, fromWave, skipWaves, toWave, clearFirst
	DoPrompt "Define Sets as True ( 1 )", setName, fromWave, toWave, skipWaves, clearFirst
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	//value -= 1
	clearFirst -= 1
	
	SetNMstr( prefixFolder+"SetsDefineSelect", setName )
	SetNMvar( prefixFolder+"SetsFromWave", fromWave )
	SetNMvar( prefixFolder+"SetsToWave", toWave )
	SetNMvar( prefixFolder+"SetsSkipWaves", skipWaves )
	//SetNMvar( prefixFolder+"SetsDefineValue", value )
	SetNMvar( prefixFolder+"SetsDefineClear", clearFirst )
	
	fromWave = max( fromWave, 0 )
	fromWave = min( fromWave, wlimit )
	
	toWave = max( toWave, 0 )
	toWave = min( toWave, wlimit )
	
	skipWaves = max( skipWaves, 0 )
	skipWaves = min( skipWaves, wlimit )
	
	if ( numtype( skipWaves ) > 0 )
		skipWaves = 0
	endif
	
	if ( !clearFirst && ( IsNMSetLockedAlert( setName ) < 0 ) )
		UpdateNMPanelSets( 1 )
		return -1
	endif
	
	return NMSetsSet( setList = setName, value = value, fromWave = fromWave, toWave = toWave, skipWaves = skipWaves, clearFirst = clearFirst, prefixFolder = "", history = 1 )

End // NMSetsDefineCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDefine( setList, value, fromWave, toWave, skipWaves, clearFirst [ prefixFolder, goToNextWave, update ] )
	String setList // set name list, or "All"
	Variable value // ( 0 ) remove from set ( 1 ) add to set
	Variable fromWave // from wave num
	Variable toWave // to wave num
	Variable skipWaves // skip wave increment ( 0 ) for none
	Variable clearFirst // zero wave first ( 0 ) no ( 1 ) yes
	String prefixFolder
	Variable goToNextWave
	Variable update
	
	Variable scnt, ccnt, wcnt, wlimit
	Variable numChannels, numWaves, currentWave
	String wName, setName, wList = ""
	
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
	
	if ( ParamIsDefault( goToNextWave ) )
		goToNextWave = 0
	endif
	
	if ( StringMatch( setList, "All" ) )
		setList = NMSetsList()
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	currentWave = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	
	wlimit = numWaves - 1
	
	if ( ( numtype( fromWave ) > 0 ) || ( fromWave < 0 ) )
		fromWave = 0
	endif
	
	if ( ( numtype( toWave ) > 0 ) || ( toWave < 0 ) )
		toWave = wlimit
	endif
	
	if ( ( numtype( skipWaves ) > 0 ) || ( skipWaves < 0 ) )
		skipWaves = 0
	endif
	
	fromWave = max( fromWave, 0 )
	fromWave = min( fromWave, wlimit )
	
	toWave = max( toWave, 0 )
	toWave = min( toWave, wlimit )
	
	skipWaves = max( skipWaves, 0 )
	skipWaves = min( skipWaves, wlimit )
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( !clearFirst && IsNMSetLocked( setName, prefixFolder = prefixFolder ) )
			continue
		endif
		
		if ( clearFirst && AreNMSets( setName, prefixFolder = prefixFolder ) )
			NMSetsEqLockTableClear( setName, prefixFolder = prefixFolder )
			NMSetsClear( setName, prefixFolder = prefixFolder, update = 0 )
		endif
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
			
			for ( wcnt = fromWave ; wcnt <= toWave ; wcnt += 1+skipWaves )
			
				wName = NMChanWaveName( ccnt, wcnt, prefixFolder = prefixFolder )
				wList += wName + ";"

			endfor
			
			if ( ItemsInList( wList ) == 0 )
				continue
			endif
			
			if ( value == 1 )
				NMSetsWaveListAdd( wList, setName, ccnt, prefixFolder = prefixFolder )
			else
				NMSetsWaveListRemove( wList, setName, ccnt, prefixFolder = prefixFolder )
			endif
			
		endfor
			
	endfor
	
	if ( goToNextWave )
		NMNextWave( +1, update = 0 )
		ChanGraphsUpdate()
		NMAutoTabCall()
	endif
	
	if ( update )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	return 0

End // NMSetsDefine

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAssignCall( setName, value )
	String setName
	Variable value
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	Variable currentWave = CurrentNMWave()
	
	if ( IsNMSetLockedAlert( setName ) < 0 )
		UpdateNMPanelSets( 1 )
		return -1
	endif
	
	return NMSetsSet( setList = setName, value = value, waveNum = currentWave, prefixFolder = "", history = 1 )

End // NMSetsAssignCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsAssign2( setName, wName, value [ prefixFolder, update ] )
	String setName
	String wName
	Variable value // 0 or 1
	String prefixFolder
	Variable update
	
	Variable ccnt, wcnt, rvalue, foundWaveNum = -1
	Variable numChannels, numWaves
	String wList, wName2
	
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
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
			wName2 = NMChanWaveName( ccnt, wcnt, prefixFolder = prefixFolder )
			
			if ( StringMatch( wName, wName2 ) )
				foundWaveNum = wcnt
				break
			endif
		
		endfor
	endfor
	
	if ( foundWaveNum < 0 )
		return -1
	endif
	
	rvalue = NMSetsDefine( setName, value, foundWaveNum, foundWaveNum, 0, 0, prefixFolder = prefixFolder, update = 0 )
	
	if ( update && ( rvalue >= 0 ) )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	return 0

End // NMSetsAssign2

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsToggleCall( setName )
	String setName
	
	Variable value, waveNum, chanNum
	String wName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) ==  0 )
		return -1
	endif
	
	if ( IsNMSetLockedAlert( setName ) < 0 )
		UpdateNMPanelSets( 1 )
		return -1
	endif
	
	waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	chanNum = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	
	wName = NMChanWaveName( chanNum, waveNum, prefixFolder = prefixFolder )
	
	value = IsNMSetsItem( setName, chanNum, wName, prefixFolder = prefixFolder )
	
	return NMSetsSet( setList = setName , value = BinaryInvert( value ) , waveNum = waveNum , prefixFolder = "", history = 1 )
	
	//return NMSetsToggle( setName, waveNum = waveNum, prefixFolder = prefixFolder, history = 1 )

End // NMSetsToggleCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsInvertCall( setName )
	String setName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( strlen( setName ) == 0 )

		Prompt setName, " ", popup NMSetsList()
		DoPrompt "Invert Sets", setName
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
	endif
	
	if ( IsNMSetLockedAlert( setName ) < 0 )
		UpdateNMPanelSets( 1 )
		return -1
	endif
	
	return NMSetsInvert( setName, prefixFolder = prefixFolder, history = 1 )

End // NMSetsInvertCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsInvert( setList [ prefixFolder, update, history ] )
	String setList // set name list, or "All"
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable scnt, ccnt, numChannels
	String setName, strVarName, wList, chanList, eList
	
	String vlist = NMCmdStr( setList, "" )
	
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
	
	if ( StringMatch( setList, "All" ) )
		setList = NMSetsList()
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	eList = NMSetsListCheck( "NMSetsInvert", setList, 1, prefixFolder = prefixFolder )
	
	if ( ItemsInList( eList ) > 0 )
		return -1
	endif
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( strlen( setName ) == 0 )
			continue
		endif
		
		if ( IsNMSetLocked( setName, prefixFolder = prefixFolder ) )
			continue
		endif
		
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			chanList = NMChanWaveList( ccnt, prefixFolder = prefixFolder )
		
			strVarName = NMSetsStrVarName( setName, ccnt, prefixFolder = prefixFolder )
			
			if ( exists( strVarName ) != 2 )
				continue
			endif
			
			wList = StrVarOrDefault( strVarName, "" )
			
			chanList = RemoveFromList( wList, chanList )
			
			SetNMstr( strVarName, chanList )
			
		endfor
	
	endfor
	
	if ( update )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	return 0

End // NMSetsInvert

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsConvertCall()

	Variable wcnt, numWaves
	String conversionWave, wList, setName, vlist = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wList = WaveList( "*", ";", "TEXT:0" )
	
	if ( ItemsInList( wList ) == 0 )
	
		DoAlert 0, "Abort Sets Convert: found no appropriate waves for this function."
		
		return 0
		
	endif
	
	wList = " ;" + wList
	
	conversionWave = " "
	
	Prompt conversionWave, "select a wave containing 1's and 0's:", popup wList
	Prompt setName, "this wave will be converted to:", popup NMSetsList()
	DoPrompt "Sets Conversion", conversionWave, setName

	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	return NMSetsSet( setList = setName, conversionWave = conversionWave, prefixFolder = "", history = 1 )

End // NMSetsConvertCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsConvert( conversionWave, setList [ prefixFolder, update ] )
	String conversionWave
	String setList // set name list, or "All"
	String prefixFolder
	Variable update
	
	Variable scnt
	String setName
	
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
	
	if ( !WaveExists( $conversionWave ) )
		return NM2Error( 1, "conversionWave", conversionWave )
	endif
	
	if ( StringMatch( setList, "All" ) )
		setList = NMSetsList()
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		NMSetsKill( setName, prefixFolder = prefixFolder, update = 0 )
		NMPrefixFolderWaveToLists( conversionWave, NMSetsStrVarPrefix( setName ), prefixFolder = prefixFolder )
		
	endfor
	
	if ( update )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif

	return 0

End // NMSetsConvert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsEquationParse( equation, select )
	String equation
	String select
	
	Variable icnt
	
	String setName = ""
	String arg1 = ""
	String op = ""
	String arg2 = ""
	
	if ( ( strlen( equation ) == 0 ) || ( strsearch( equation, "=", 0 ) < 0 ) )
		return ""
	endif
	
	equation = ReplaceString( "&&", equation, "&" )
	equation = ReplaceString( "AND", equation, "&" )
	equation = ReplaceString( "||", equation, "|" )
	equation = ReplaceString( "OR", equation, "|" )
	
	icnt = strsearch( equation, "&", 0 )
	
	if ( icnt > 0 )
	
		op = "AND"
		
	else
	
		icnt = strsearch( equation, "|", 0 )
		
		if ( icnt > 0 )
			op = "OR"
		endif
	
	endif
	
	strswitch( select )
	
		case "set":
		case "setName":
		
			icnt = strsearch( equation, "=", 0 )
			
			setName = equation[ 0, icnt - 1 ]
			
			setName = ReplaceString( " ", setName, "" )
			
			return setName
	
		case "arg1":
		
			icnt = strsearch( equation, "=", 0 )
			
			arg1 = equation[ icnt + 1, inf ]
			
			icnt = strsearch( arg1, "&", 0 )
			
			if ( icnt < 0 )
				icnt = strsearch( arg1, "|", 0 )
			endif
			
			if ( icnt > 0 )
				arg1 = arg1[ 0, icnt - 1 ]
			endif
			
			arg1 = ReplaceString( " ", arg1, "" )
			
			return arg1
			
		case "op":
			return op
			
		case "arg2":
		
			if ( strlen( op ) == 0 )
				return arg2
			endif
		
			icnt = strsearch( equation, "=", 0 )
			
			arg2 = equation[ icnt + 1, inf ]
			
			icnt = strsearch( arg2, "&", 0 )
			
			if ( icnt < 0 )
				icnt = strsearch( arg2, "|", 0 )
			endif
			
			if ( icnt > 0 )
				arg2 = arg2[ icnt + 1, inf ]
			endif
			
			arg2 = ReplaceString( " ", arg2, "" )
			
			return arg2
	
	endswitch
	
	return ""
	
End // NMSetsEquationParse

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEquationCall()
	
	String eq
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsFxnName", "Set1" )
	String arg1 = StrVarOrDefault( prefixFolder+"SetsFxnArg1", " " )
	String op = StrVarOrDefault( prefixFolder+"SetsFxnOp", " " )
	String arg2 = StrVarOrDefault( prefixFolder+"SetsFxnArg2", " " )
	Variable locked = 1 + NumVarOrDefault( prefixFolder+"SetsFxnLocked", 1 )
	
	String setList = NMSetsList() + NMGroupsList( 1 )
	
	if ( StringMatch( op, " " ) )
		arg2 = " "
	endif
	
	Prompt setName, " ", popup setList
	Prompt arg1, " = ", popup " ;" + setList
	Prompt op, " ", popup " ;AND;OR;"
	Prompt arg2, " ", popup " ;" + setList
	Prompt locked, " ", popup "execute this equation once only;lock this equation;"
	
	DoPrompt "Sets Equation", setName, arg1, op, arg2, locked
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	if ( StringMatch( op, " " ) )
		op = ""
	endif
	
	if ( StringMatch( arg1, " " ) )
		arg1 = ""
	endif
	
	if ( StringMatch( arg2, " " ) )
		arg2 = ""
	endif
	
	locked -= 1
	
	SetNMstr( prefixFolder+"SetsFxnName", setName )
	SetNMstr( prefixFolder+"SetsFxnArg1", arg1 )
	SetNMstr( prefixFolder+"SetsFxnOp", op )
	SetNMstr( prefixFolder+"SetsFxnArg2", arg2 )
	SetNMvar( prefixFolder+"SetsFxnLocked", locked )
	
	eq = setName + " = " + arg1
	
	if ( strlen( op ) > 0 )
		eq += " " + op + " " + arg2
	endif
	
	if ( locked )
		return NMSetsSet( equationLocked = eq, prefixFolder = "", history = 1 )
	else
		return NMSetsSet( equation = eq, prefixFolder = "", history = 1 )
	endif

End // NMSetsEquationCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEquation( setName, arg1, operation, arg2 [ prefixFolder, update ] ) // Set = arg1 AND arg2
	String setName // e.g. "Set1"
	String arg1 // argument #1 ( e.g. "Set1" or "Group2" )
	String operation // operator ( "AND", "OR", "" )
	String arg2 // argument #1 ( e.g. "Set2" or "Group2" or "" )
	String prefixFolder
	Variable update
	
	Variable numChannels, ccnt, grp1 = Nan, grp2 = Nan
	String wList1, wList2, thisfxn = GetRTStackInfo( 1 )
	
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
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	if ( numChannels <= 0 )
		NMDoAlert( thisfxn + " Abort: no channels: " + num2istr( numChannels ) )
		return -1
	endif
	
	if ( strlen( setName ) == 0 )
		NMDoAlert( thisfxn + " Abort: parameter setName is undefined." )
		return -1
	endif
	
	if ( strlen( arg1 ) == 0 )
		NMDoAlert( thisfxn + " Abort: parameter arg1 is undefined." )
		return -1
	endif
	
	strswitch( operation )
	
		case "AND":
		case "&":
		case "&&":
			operation = "AND"
			break
			
		case "OR":
		case "|":
		case "||":
			operation = "OR"
			break
			
		default:
			operation = ""
			arg2 = ""
	
	endswitch
	
	if ( StringMatch( arg1[0,4], "Group" ) )
		grp1 = str2num( arg1[5,inf] )
	elseif ( !AreNMSets( arg1, prefixFolder = prefixFolder ) )
		NMDoAlert( thisfxn + " Abort: " + arg1 + " does not exist." )
		return -1
	endif
	
	if ( StringMatch( arg2[0,4], "Group" ) )
		grp2 = str2num( arg2[5,inf] )
	elseif ( ( strlen( arg2 ) > 0 ) && !AreNMSets( arg2, prefixFolder = prefixFolder ) )
		NMDoAlert( thisfxn + " Abort: " + arg2 + " does not exist." )
		return -1
	endif
	
	if ( AreNMSets( setName, prefixFolder = prefixFolder ) )
		NMSetsClear( setName, prefixFolder = prefixFolder, update = 0, clearEqLock = 0 )
	endif
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		wList1 = ""
		wList2 = ""
	
		if ( numtype( grp1 ) == 0 )
			wList1 = NMGroupsWaveList( grp1, ccnt, prefixFolder = prefixFolder )
		else
			wList1 = NMSetsWaveList( arg1, ccnt, prefixFolder = prefixFolder )
		endif
		
		if ( strlen( arg2 ) > 0 )
		
			if ( numtype( grp2 ) == 0 )
				wList2 = NMGroupsWaveList( grp2, ccnt, prefixFolder = prefixFolder )
			else
				wList2 = NMSetsWaveList( arg2, ccnt, prefixFolder = prefixFolder )
			endif
			
			strswitch( operation )
				
				case "AND":
					wList1 = NMAndLists( wList2, wList1, ";" )
					break
		
				case "OR":
					wList1 = NMAddToList( wList2, wList1, ";" )
					break
			
				default:
					return -1
	
			endswitch
		
		endif
		
		NMSetsWaveListAdd( wList1, setName, ccnt, prefixFolder = prefixFolder )
		
	endfor
	
	if ( update )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	return 0

End // NMSetsEquation

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEquationAll( outName, operation [ prefixFolder ] ) // NOT USED
	String outName // output set name
	String operation // "AND" or "OR"
	String prefixFolder
	
	Variable scnt, ccnt, numChannels
	String setList, setName, wList1, wList2
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	setList = NMSetsList( prefixFolder = prefixFolder )
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	strswitch( operation )
				
		case "AND":
		case "&":
		case "&&":
			operation = "AND"
			break

		case "OR":
		case "|":
		case "||":
			operation = "OR"
			break
	
		default:
			return -1
			
	endswitch
	
	if ( NMSetXType( prefixFolder = prefixFolder ) == 1 )
		setList = RemoveFromList( "SetX", setList )
	endif
	
	CheckNMSetsExist( outName, prefixFolder = prefixFolder )
	NMSetsClear( outName, prefixFolder = prefixFolder, update = 0 )
	
	if ( ItemsInList( setList ) <= 0 )
		return 0
	endif
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
			setName = StringFromList( scnt, setList )
			wList2 = NMSetsWaveList( setName, ccnt, prefixFolder = prefixFolder )
			
			if ( scnt == 0 )
				wList1 = wList2
				continue
			endif
			
			strswitch( operation )
				
				case "AND":
					wList1 = NMAndLists( wList1, wList2, ";" )
					break
		
				case "OR":
					wList1 = NMAddToList( wList2, wList1, ";" )
					break
					
			endswitch
	
		endfor
		
		NMSetsWaveListAdd( wList1, outName, ccnt, prefixFolder = prefixFolder )
		
	endfor
	
	return 0
	
End // NMSetsEquationAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEquationLock( setName, arg1, operation, arg2 [ prefixFolder, update ] )
	String setName // e.g. "Set1"
	String arg1 // argument #1 ( e.g. "Set1" or "Group2" )
	String operation // operator ( "AND", "OR", "" )
	String arg2 // argument #1 ( e.g. "Set2" or "Group2" )
	String prefixFolder
	Variable update
	
	Variable rvalue, kill
	String thisfxn = GetRTStackInfo( 1 )
	
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
	
	if ( ( strlen( arg1 ) == 0 ) && ( strlen( operation ) == 0 ) && ( strlen( arg2 ) == 0 ) )
	
		kill = 1
		
	else
	
		if ( strlen( arg1 ) == 0 )
	
			NMDoAlert( thisfxn + " Abort: no value for arg1" )
		
			return -1
		
		endif
		
		strswitch( operation )
			
			case "AND":
			case "OR":
			case "":
				break
				
			default:
			
				NMDoAlert( thisfxn + " Abort: bad operation: " + operation )
	
				return -1
		
		endswitch
		
		if ( ( strlen( operation ) > 0 ) && ( strlen( arg2 ) == 0 ) )
		
			NMDoAlert( thisfxn + " Abort: no value for arg2" )
		
			return -1
		
		endif
		
	endif
	
	if ( !kill )
	
		rvalue = NMSetsEquation( setName, arg1, operation, arg2, prefixFolder = prefixFolder, update = 0 )
	
		if ( rvalue < 0 )
			return -1
		endif
		
	endif
	
	 rvalue = NMSetsEqLockTableAdd( setName, arg1, operation, arg2, prefixFolder = prefixFolder )
	 
	 NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
	
	if ( update && ( rvalue >= 0 ) )
		UpdateNMPanelSets( 1 )
	endif
	
	return rvalue
	
End // NMSetsEquationLock

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsEqLockWaveName( [ prefixFolder ] )
	String prefixFolder

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return prefixFolder + "SetsFxnsLocked"

End // NMSetsEqLockWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEqLockTableEdit( [ prefixFolder, history ] )
	String prefixFolder
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	String tName, tTitle, wName, parent, prefix, vlist = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	wName = NMSetsEqLockWaveName( prefixFolder = prefixFolder )
	
	if ( !WaveExists( $wName ) )
	
		NMDoAlert( "There are currently no locked equations." )
	
		return 0
	
	endif
	
	prefix = NMChild( prefixFolder )
	prefix = ReplaceString( NMPrefixSubfolderPrefix, prefix, "" )
	
	parent = NMParent( prefixFolder )
	parent = NMChild( parent )
	
	tName = "NM_SetsLockedEqTable"
	tTitle = "Locked Set Equations : " + parent + " : " + prefix
	
	NMTable( wList = wname, tName = tName, tTitle = tTitle )
	
	return 0
	
End // NMSetsEqLockTableEdit

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEqLockTablePrint( [ prefixFolder, history ] )
	String prefixFolder
	Variable history // print function command to history ( 0 ) no ( 1 ) yes

	Variable ipnts, icnt, found
	String eq, wName, vlist = ""
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		vlist = NMCmdStrOptional( "prefixFolder", prefixFolder, vlist )
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	wName = NMSetsEqLockWaveName( prefixFolder = prefixFolder )
	
	if ( !WaveExists( $wName ) )
	
		NMDoAlert( "There are currently no locked equations." )
	
		return 0
	
	endif
	
	Wave /T wtemp = $wName
	
	if ( DimSize( wtemp, 1 ) != 4 )
		return 0 // something wrong
	endif
	
	ipnts = DimSize( wtemp, 0 )
	
	for ( icnt = 0 ; icnt < ipnts ; icnt += 1 )
	
		if ( strlen( wtemp[ icnt ][ 0 ] ) > 0 )
		
			found = 1
		
			eq = wtemp[ icnt ][ 0 ] + " = " + wtemp[ icnt ][ 1 ] + " " + wtemp[ icnt ][ 2 ] + " " + wtemp[ icnt ][ 3 ]
			
			NMHistory( eq )
			
		endif
		
	endfor
	
	if ( !found )
		NMDoAlert( "There are currently no locked equations." )
	endif
	
	return 0
	
End // NMSetsEqLockTablePrint

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEqLockTableAdd( setName, arg1, operation, arg2 [ prefixFolder ] )
	String setName // e.g. "Set1"
	String arg1 // argument #1 ( e.g. "Set1" or "Group2" )
	String operation // operator ( "AND", "OR", "" )
	String arg2 // argument #1 ( e.g. "Set2" or "Group2" or "" )
	String prefixFolder
	
	// to kill a locked equation enter emptry strings, e.g. NMSetsEquationLock( "Set1", "", "", "" )
	
	Variable rvalue, icnt, ipnts, foundExisting, foundEmpty, kill
	String eq, wName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	wName = NMSetsEqLockWaveName( prefixFolder = prefixFolder )
	
	if ( strlen( wName ) == 0 )
		return -1
	endif
	
	if ( ( strlen( arg1 ) == 0 ) && ( strlen( operation ) == 0 ) && ( strlen( arg2 ) == 0 ) )
		kill = 1
	endif
	
	if ( !WaveExists( $wName ) )
		Make /T/N=( 5, 4 ) $wName = ""
	elseif ( DimSize( $wName, 1 ) != 4 )
		return -1 // something wrong
	endif
	
	Wave /T wtemp = $wName
	
	ipnts = DimSize( wtemp, 0 )
	
	eq = setName + " = " + arg1 + " " + operation + " " + arg2
	
	for ( icnt = 0 ; icnt < ipnts ; icnt += 1 )
	
		if ( StringMatch( setName, wtemp[ icnt ][ 0 ] ) )
		
			foundExisting = 1
			
			if ( kill )
			
				eq = wtemp[ icnt ][ 0 ] + " = " + wtemp[ icnt ][ 1 ] + " " + wtemp[ icnt ][ 2 ] + " " + wtemp[ icnt ][ 3 ]
			
				wtemp[ icnt ][ 0 ] = ""
				wtemp[ icnt ][ 1 ] = ""
				wtemp[ icnt ][ 2 ] = ""
				wtemp[ icnt ][ 3 ] = ""
				
				NMHistory( "NM Locked Sets : killed the following equation : " + eq )
			
			else // replace existing equation
			
				wtemp[ icnt ][ 1 ] = arg1
				wtemp[ icnt ][ 2 ] = operation
				wtemp[ icnt ][ 3 ] = arg2
			
			endif
			
		endif
	
	endfor
	
	if ( kill )
	
		return 0
		
	elseif ( foundExisting )
	
		NMHistory( "NM Locked Sets : added the following equation : " + eq )
		
		return 0
		
	endif
	
	// found no existing equation, so make new entry
	
	for ( icnt = 0 ; icnt < ipnts ; icnt += 1 )
		
		if ( strlen( wtemp[ icnt ][ 0 ] ) == 0 )
			foundEmpty = 1
			break
		endif
	
	endfor
	
	if ( !foundEmpty )
	
		Redimension /N=( ipnts+5, 4 ) wtemp
		
		for ( icnt = 0 ; icnt < ipnts ; icnt += 1 )
		
			if ( strlen( wtemp[ icnt ][ 0 ] ) == 0 )
				foundEmpty = 1
				break
			endif
		
		endfor
		
		if ( !foundEmpty )
			return -1 // shouldnt happen
		endif
		
	endif
	
	wtemp[ icnt ][ 0 ] = setName
	wtemp[ icnt ][ 1 ] = arg1
	wtemp[ icnt ][ 2 ] = operation
	wtemp[ icnt ][ 3 ] = arg2
	
	NMHistory( "NM Locked Sets : added the following equation : " + eq )
	
	return 0
	
End // NMSetsEqLockTableAdd

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEqLockTableClear( setList [ prefixFolder ] )
	String setList // set name list
	String prefixFolder
	
	Variable scnt
	String setName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	for ( scnt = 0; scnt < ItemsInList( setList ); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		NMSetsEqLockTableAdd( setName, "", "", "", prefixFolder = prefixFolder )
	
	endfor
	
	return 0

End // NMSetsEqLockTableClear

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsEqLockTableFind( setName, select [ prefixFolder ] )
	String setName
	String select // see strswitch below
	String prefixFolder
	
	Variable icnt, ipnts
	String eq, txt, wName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif

	wName = NMSetsEqLockWaveName( prefixFolder = prefixFolder )
	
	if ( ( strlen( wName ) == 0 ) || !WaveExists( $wName ) || ( DimSize( $wName, 1 ) != 4 ) )
		return ""
	endif
	
	Wave /T wtemp = $wName
	
	ipnts = DimSize( wtemp, 0 )
	
	for ( icnt = 0 ; icnt < ipnts ; icnt += 1 )
	
		if ( strlen( wtemp[ icnt ][ 0 ] ) == 0 )
			continue
		endif
		
		if ( StringMatch( setName, wtemp[ icnt ][ 0 ] ) )
			
			strswitch( select )
			
				case "all":
					return wtemp[ icnt ][ 0 ] + " = " + wtemp[ icnt ][ 1 ] + " " + wtemp[ icnt ][ 2 ] + " " + wtemp[ icnt ][ 3 ]
			
				case "arg1":
					return wtemp[ icnt ][ 1 ]
				
				case "op":
				case "operation":
					return wtemp[ icnt ][ 2 ]
					
				case "arg2":
					return wtemp[ icnt ][ 3 ]
			
			endswitch
			
		endif
		
	endfor
	
	return ""
	
End // NMSetsEqLockTableFind

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsEqLockTableUpdate( [ prefixFolder ] )
	String prefixFolder
	
	Variable icnt, ipnts, foundOperation
	String eq, txt, wName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	wName = NMSetsEqLockWaveName( prefixFolder = prefixFolder )
	
	if ( !WaveExists( $wName ) || ( DimSize( $wName, 1 ) != 4 ) )
		return -1
	endif
	
	Wave /T wtemp = $wName
	
	ipnts = DimSize( wtemp, 0 )
	
	for ( icnt = 0 ; icnt < ipnts ; icnt += 1 )
	
		if ( strlen( wtemp[ icnt ][ 0 ] ) == 0 )
			continue
		endif
		
		eq = wtemp[ icnt ][ 0 ] + " = " + wtemp[ icnt ][ 1 ] + " " + wtemp[ icnt ][ 2 ] + " " + wtemp[ icnt ][ 3 ]
		
		if ( !AreNMSets( wtemp[ icnt ][ 0 ], prefixFolder = prefixFolder ) )
		
			NMHistory( "NM Locked Sets : killed the following invalid equation : " + eq )
		
			wtemp[ icnt ][ 0 ] = ""
			wtemp[ icnt ][ 1 ] = ""
			wtemp[ icnt ][ 2 ] = ""
			wtemp[ icnt ][ 3 ] = ""
			
			continue
			
		endif
		
		if ( !AreNMSets( wtemp[ icnt ][ 1 ], prefixFolder = prefixFolder ) )
		
			txt = wtemp[ icnt ][ 1 ]
		
			if ( !StringMatch( txt[ 0, 4 ], "Group" ) )
		
				NMHistory( "NM Locked Sets : killed the following invalid equation : " + eq )
			
				wtemp[ icnt ][ 0 ] = ""
				wtemp[ icnt ][ 1 ] = ""
				wtemp[ icnt ][ 2 ] = ""
				wtemp[ icnt ][ 3 ] = ""
			
				continue
			
			endif
			
		endif
		
		strswitch( wtemp[ icnt ][ 2 ] )
		
			case "AND":
			case "OR":
				foundOperation = 1
				break
			case "":
				foundOperation = 0
				break
		
			default:
				foundOperation = NaN
				
		endswitch
		
		if ( numtype( foundOperation ) > 0 )
		
			NMHistory( "NM Locked Sets : killed the following invalid equation : " + eq )
		
			wtemp[ icnt ][ 0 ] = ""
			wtemp[ icnt ][ 1 ] = ""
			wtemp[ icnt ][ 2 ] = ""
			wtemp[ icnt ][ 3 ] = ""
			
			continue
			
		endif
		
		if ( foundOperation && !AreNMSets( wtemp[ icnt ][ 3 ], prefixFolder = prefixFolder ) )
		
			txt = wtemp[ icnt ][ 3 ]
		
			if ( !StringMatch( txt[ 0, 4 ], "Group" ) )
		
				NMHistory( "NM Locked Sets : killed the following invalid equation : " + eq )
			
				wtemp[ icnt ][ 0 ] = ""
				wtemp[ icnt ][ 1 ] = ""
				wtemp[ icnt ][ 2 ] = ""
				wtemp[ icnt ][ 3 ] = ""
			
				continue
			
			endif
			
		endif
		
		NMSetsEquation( wtemp[ icnt ][ 0 ], wtemp[ icnt ][ 1 ], wtemp[ icnt ][ 2 ], wtemp[ icnt ][ 3 ], prefixFolder = prefixFolder, update = 0 )
		
	endfor

End // NMSetsEqLockTableUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMSetLocked( setName [ prefixFolder ] )
	String setName
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	if ( strlen( NMSetsEqLockTableFind( setName, "all", prefixFolder = prefixFolder ) ) > 0 )
		return 1
	endif
	
	return 0
	
End // IsNMSetLocked

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMSetLockedAlert( setName [ prefixFolder ] )
	String setName
	String prefixFolder
	
	String eq
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	eq = NMSetsEqLockTableFind( setName, "all", prefixFolder = prefixFolder )
	
	if ( strlen( eq ) == 0 )
		return 0
	endif
	
	DoAlert 1, setName + " is locked by the equation: " + eq + ". Do you want to clear this equation and continue?"
	
	if ( V_flag == 1 )
	
		NMSetsEqLockTableClear( setName, prefixFolder = prefixFolder )
	
		return 0
	
	endif
	
	return -1

End // IsNMSetLockedAlert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsDisplayList( [ prefixFolder ] )
	String prefixFolder

	String setList = ""

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) > 0 )
		setList = StrVarOrDefault( prefixFolder+"SetsDisplayList", "" )
	endif
	
	if ( ItemsInList( setList ) > 0 )
		return setList
	else
		return NMSetsListDefault
	endif

End // NMSetsDisplayList

//****************************************************************
//****************************************************************
//****************************************************************

Function IsNMSetsDisplay( setName [ prefixFolder ] )
	String setName
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	if ( WhichListItem( setName, NMSetsDisplayList( prefixFolder = prefixFolder ) ) >= 0 )
		return 1
	endif
	
	return 0
	
End // IsNMSetsDisplay

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsDisplayName( setListNum [ prefixFolder ] )
	Variable setListNum
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	return StringFromList( setListNum, NMSetsDisplayList( prefixFolder = prefixFolder ) )

End // NMSetsDisplayName

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDisplayCall()

	Variable on
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setList = NMSetsDisplayList()
	
	String s1 = StringFromList( 0, setList )
	String s2 = StringFromList( 1, setList )
	String s3 = StringFromList( 2, setList )
	
	Prompt s1, "first checkbox:", popup NMSetsList()
	Prompt s2, "second checkbox:", popup NMSetsList()
	Prompt s3, "third checkbox:", popup NMSetsList()
	DoPrompt "Main Panel Sets Display", s1, s2, s3
	
	if ( V_flag == 1 )
		return -1 // cancel
	endif
	
	setList = AddListItem( s1, "", ";", inf )
	setList = AddListItem( s2, setList, ";", inf )
	setList = AddListItem( s3, setList, ";", inf )
	
	return NMSetsSet( displayList = setList, prefixFolder = "", history = 1 )
	
End // NMSetsDisplayCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsDisplaySet( setList [ prefixFolder, update ] )
	String setList
	String prefixFolder
	Variable update
	
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
	
	if ( ItemsInList( setList ) != 3 )
		return -1
	endif
	
	String eList = NMSetsListCheck( "NMSetsDisplaySet", setList, 1, prefixFolder = prefixFolder ) 
	
	if ( ItemsInList( eList) > 0 )
		return -1
	endif
	
	SetNMstr( prefixFolder +"SetsDisplayList", setList )
	
	if ( update )
		UpdateNMPanelSets( 1 )
	endif
	
	return 0
	
End // NMSetsDisplaySet

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsCount( setName, chanNum [ prefixFolder ] )
	String setName
	Variable chanNum
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	return ItemsInList( NMSetsWaveList( setName, chanNum, prefixFolder = prefixFolder ) ) // number of waves in this set

End // NMSetsCount

//****************************************************************
//****************************************************************
//****************************************************************

Function UpdateNMSetsDisplayCount( [ prefixFolder ] ) // udpate count number for display Sets
	String prefixFolder

	Variable scnt, count, currentChan
	String setName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	currentChan = NumVarOrDefault( prefixFolder + "CurrentChan", 0 )
	
	for ( scnt = 0 ; scnt < 3 ; scnt += 1 )
	
		setName = NMSetsDisplayName( scnt, prefixFolder = prefixFolder )
		count = ItemsInList( NMSetsWaveList( setName, currentChan, prefixFolder = prefixFolder ) )
		
		SetNMvar( NMDF+"SumSet"+num2istr(scnt), count )
		
	endfor

End // UpdateNMSetsDisplayCount

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetXCall( exclude )
	Variable exclude
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( ( exclude != 0 ) && ( exclude != 1 ) )
	
		exclude = 1 + NMSetXType()
	
		Prompt exclude, "waves checked as SetX are to be excluded from analysis?", popup "no;yes"
		DoPrompt "Define SetX", exclude
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		exclude -= 1
		
	endif
	
	return NMSetsSet( setXclude = exclude, prefixFolder = "", history = 1 )
	
End // NMSetXCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetXclude( excluding [ prefixFolder, update ] )
	Variable excluding // ( 0 ) normal Set ( 1 ) excluding Set
	String prefixFolder
	Variable update
	
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
	
	excluding = BinaryCheck( excluding )
	
	SetNMvar( prefixFolder+"SetXclude", excluding )
	
	if ( update )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	return excluding
	
End // NMSetXclude

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetXType( [ prefixFolder ] ) // determine if SetX is excluding
	String prefixFolder

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return NaN
	endif
	
	if ( !AreNMSets( "SetX", prefixFolder = prefixFolder ) )
		return 1
	endif
	
	if ( NumVarOrDefault( prefixFolder + "SetXclude", 1 ) )
		return 1
	endif

	return 0

End // NMSetXType

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetXcludeWaveList( wList, chanNum [ prefixFolder ] )
	String wList
	Variable chanNum
	String prefixFolder
	
	String strVarName, wListX
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return wList
	endif
	
	if ( NMSetXType( prefixFolder = prefixFolder ) == 0 )
		return wList
	endif
	
	strVarName = NMSetsStrVarName( "SetX", chanNum, prefixFolder = prefixFolder )
	
	wListX = StrVarOrDefault( strVarName, "" )
	
	return RemoveFromList( wListX, wList )
	
End // NMSetXcludeWaveList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Set Wave Functions
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsWavesList( folder, fullPath )
	String folder
	Variable fullPath // ( 0 ) no, just wave name ( 1 ) yes, directory + wave name
	
	Variable scnt
	String setName, type, optionsStr = ""
	String setList, ignoreList, outList = ""
	
	if ( strlen( folder ) == 0 )
		return ""
	endif
	
	Variable numWaves = NumVarOrDefault( folder+"NumWaves", 0 )
	
	if ( exists( folder+"NumWaves" ) )
		optionsStr = NMWaveListOptions( numWaves, 0 )
	endif
	
	setList = NMFolderWaveList( folder, "*", ";", optionsStr, 0 )
	
	ignoreList = WaveList( "*TShift*", ";", "" )
	
	ignoreList += "WavSelect;ChanSelect;Group;FileScaleFactors;MyScaleFactors;"
	
	setList = SortList( setList, ";", 16 )
	
	if ( WhichListItem( "SetX", setList ) >= 0 )
		setList = RemoveFromList( "SetX", setList, ";" )
		setList = AddListItem( "SetX", setList, ";", inf )
	endif
	
	setList = RemoveFromList( ignoreList, setList, ";" )

	if ( ItemsInList( setList ) < 1 )
		return ""
	endif
	
	for ( scnt = 0; scnt < ItemsInList( setList); scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		type = NMNoteStrByKey( folder+setName, "Type" )
		
		if ( StringMatch( type, "NMSet" ) || StringMatch( setName[0,2], "Set" ) )
		
			if ( fullPath )
				outList = AddListItem( folder + setName, outList, ";", inf )
			else
				outList = AddListItem( setName, outList, ";", inf )
			endif
			
		endif
		
	endfor
	
	return outList
	
End // NMSetsWavesList

//****************************************************************
//****************************************************************
//****************************************************************

Function AreNMSetsWaves( setList [ prefixFolder ] )
	String setList
	String prefixFolder
	
	Variable scnt
	String setName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return 0
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( !WaveExists( $prefixFolder+setName ) )
			return 0
		endif
		
	endfor
	
	return 1
	
End // AreNMSetsWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsWavesKill( [ prefixFolder ] )
	String prefixFolder

	Variable scnt, killedsomething
	String setName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	NMSetsPanelTable( 0 ) // if table exists, remove Set waves

	String setList = NMSetsWavesList( prefixFolder, 0 )
	
	for ( scnt = 0 ; scnt <ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		
		if ( AreNMSets( setName, prefixFolder = prefixFolder ) )
			KillWaves /Z $prefixFolder+setName // kill only if Set string lists exist
		endif
		
		if ( !WaveExists( $prefixFolder+setName ) )
			killedsomething = 1
		endif
		
	endfor

	return killedsomething

End // NMSetsWavesKill

//****************************************************************
//****************************************************************
//****************************************************************

Function OldNMSetsWavesToLists( setList [ prefixFolder ] )
	String setList
	String prefixFolder
	
	Variable scnt, xtype
	String setName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
		
		setName = StringFromList( scnt, setList )
		
		if ( !AreNMSets( setName, prefixFolder = prefixFolder ) )
			
			if ( StringMatch( setName, "SetX" ) )
			
				xtype = NMNoteVarByKey( prefixFolder+"SetX", "Excluding" )
			
				if ( xtype == 0 )
					SetNMvar( prefixFolder+"SetXclude", 0 )
				endif
				
			endif
			
			NMSetsWavesToLists( setName, prefixFolder = prefixFolder )
			
		endif
		
		if ( AreNMSets( setName, prefixFolder = prefixFolder ) )
			KillWaves /Z $prefixFolder+setName
		endif
		
	endfor
		
End // OldNMSetsWavesToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsWaveToLists( setWaveName, newSetName [ prefixFolder ] )
	String setWaveName
	String newSetName
	String prefixFolder
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( !WaveExists( $setWaveName ) )
		NMDoAlert( "Abort NMSetsWaveToLists: wave does not exist: " + setWaveName )
		return -1
	endif
	
	return NMPrefixFolderWaveToLists( setWaveName, NMSetsStrVarPrefix( newSetName ), prefixFolder = prefixFolder )
	
End // NMSetsWaveToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsWavesToLists( setList [ prefixFolder ] )
	String setList
	String prefixFolder
	
	Variable scnt
	String setName, inputWaveName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		inputWaveName = prefixFolder+setName
		
		NMPrefixFolderWaveToLists( inputWaveName, NMSetsStrVarPrefix( setName ), prefixFolder = prefixFolder )
	
	endfor
	
	return 0
	
End // NMSetsWavesToLists

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsListsToWavesAll( [ prefixFolder ] )
	String prefixFolder
	
	String setList
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	setList = NMSetsList( prefixFolder = prefixFolder )

	NMSetsListsToWaves( setList, prefixFolder = prefixFolder )
	
	NMSetsWavesTag( setList, prefixFolder = prefixFolder )
	
	return 0

End // NMSetsListsToWavesAll

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsListsToWaves( setList [ prefixFolder ] )
	String setList
	String prefixFolder

	Variable scnt
	String setName, outputWaveName
	
	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
		outputWaveName = prefixFolder+setName
		
		NMPrefixFolderListsToWave( NMSetsStrVarPrefix( setName ), outputWaveName, prefixFolder = prefixFolder )
		
		NMSetsWavesTag( outputWaveName, prefixFolder = prefixFolder )
		
	endfor
	
	return 0

End // NMSetsListsToWaves

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsWavesTag( setList [ prefixFolder ] )
	String setList
	String prefixFolder
	
	Variable icnt
	String setName, wnote, prefix
	
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
	
	for ( icnt = 0; icnt < ItemsInList( setList ); icnt += 1 )
	
		setName = StringFromList( icnt, setList )
		
		if ( !WaveExists( $setName ) )
			continue
		endif
		
		if ( StringMatch( NMNoteStrByKey( setName, "Type" ), "NMSet" ) )
			continue
		endif
		
		wnote = "WPrefix:" + prefix
		
		if ( StringMatch( setName, "SetX" ) )
			wnote += NMCR + "Excluding:" + num2str( NMSetXType( prefixFolder = prefixFolder ) )
		endif
		
		NMNoteType( setName, "NMSet", "Wave#", "True ( 1 ) / False ( 0 )", wnote )
		
		Note $setName, "DEPRECATED: Set waves are no longer utilized by NeuroMatic. Please use Set list string variables instead."
		
	endfor
	
	return 0

End // NMSetsWavesTag

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsListsUpdateNewChannels( [ prefixFolder ] )
	String prefixFolder
	
	String setList

	if ( ParamIsDefault( prefixFolder ) )
		prefixFolder = CurrentNMPrefixFolder()
	else
		prefixFolder = CheckNMPrefixFolderPath( prefixFolder )
	endif
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	setList = NMSetsList( prefixFolder = prefixFolder )
	
	NMSetsWavesKill( prefixFolder = prefixFolder )
	
	NMSetsListsToWaves( setList, prefixFolder = prefixFolder )
	
	NMSetsKill( setList, prefixFolder = prefixFolder, update = 0 )
	NMSetsWavesToLists( setList, prefixFolder = prefixFolder )
	
	NMSetsWavesKill( prefixFolder = prefixFolder )
	
End // NMSetsListsUpdateNewChannels

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsListsCopy( fromPrefixFolder, toPrefixFolder )
	String fromPrefixFolder, toPrefixFolder
	
	Variable icnt
	String setListName, wList1, wList2
	
	if ( !DataFolderExists( fromPrefixFolder ) )
		return NM2Error( 30, "fromPrefixFolder", fromPrefixFolder )
	endif
	
	if ( !DataFolderExists( toPrefixFolder ) )
		return NM2Error( 30, "toPrefixFolder", toPrefixFolder )
	endif
	
	String setsList = NMFolderStringList( fromPrefixFolder, "*_SetList*", ";", 0 )
	
	for ( icnt = 0 ; icnt < ItemsInList( setsList ) ; icnt += 1 )
	
		setListName = StringFromList( icnt, setsList )
		
		wList1 = StrVarOrDefault( fromPrefixFolder + setListName, "" )
				
		if ( ItemsInList( wList1 ) == 0 )
			continue
		endif
		
		wList2 = StrVarOrDefault( toPrefixFolder + setListName, "" )
		
		wList2 = NMAddToList( wList1, wList2, ";" )
				
		SetNMstr( toPrefixFolder + setListName, wList2 )
		
	endfor

	return 0

End // NMSetsListsCopy

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Sets Panel Functions
//	works only with Current Prefix Folder
//
//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelList()

	return NMSetsWavesList( CurrentNMPrefixFolder(), 0 )

End // NMSetsPanelList

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanel( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable x1, x2, y1, y2, width = 600, height = 400
	Variable x0 = 35, y0 = 15, xinc = 100, yinc = 35
	
	Variable numWaves
	String txt, firstSet, setName
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	String tname = NMSetsPanelName + "Table"
	
	Variable fs = NMPanelFsize
	Variable xpixels = NMScreenPixelsX()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	//DoWindow /k $NMSetsPanelName
	
	if ( WinType( NMSetsPanelName ) > 0 )
		DoWindow /F $NMSetsPanelName
		return 0
	endif
	
	x1 = ( xpixels - width ) /2
	y1 = 140
	x2 = x1 + width
	y2 = y1 + height
	
	SetNMvar( NMDF+"SetsPanelChange", 0 )
	
	CheckNMvar( prefixFolder+"SetsFromWave", 0 )
	CheckNMvar( prefixFolder+"SetsToWave", max( numwaves-1, 0 ) )
	CheckNMvar( prefixFolder+"SetsSkipWaves", 0 )
	CheckNMvar( prefixFolder+"SetsDefineValue", 1 )
	
	CheckNMvar( NMDF+"SetsPanelAutoSave", 1 )
	
	DoWindow /K$NMSetsPanelName
	NewPanel /K=1/N=$NMSetsPanelName/W=( x1,y1,x2,y2 ) as "Edit Sets"
	SetWindow $NMSetsPanelName hook(setspanel)=NMSetsPanelHook
	
	PopupMenu NM_SetsSelect, title=" ", pos={x0+215,y0}, size={0,0}, bodyWidth=160, fsize=fs
	PopupMenu NM_SetsSelect, mode=1, value=" ", proc=NMSetsPanelPopup
	
	x0 = 35
	y0 += 65
	
	GroupBox NM_SetsPanelGrp, title = "Define ( 010010... )", pos={x0-20,y0-30}, size={310,135}, fsize=fs
	
	SetVariable NM_SetsFromWave, title="FROM wave: ", limits={0,inf,0}, pos={x0,y0+0*yinc}, size={145,50}
	SetVariable NM_SetsFromWave, value=$( prefixFolder+"SetsFromWave" ), fsize=fs, proc=NMSetsPanelVariable
	
	SetVariable NM_SetsToWave, title="TO wave: ", limits={0,inf,0}, pos={x0,y0+1*yinc}, size={145,50}
	SetVariable NM_SetsToWave, value=$( prefixFolder+"SetsToWave" ), fsize=fs, proc=NMSetsPanelVariable
	
	SetVariable NM_SetsSkipWaves, title="SKIP every other: ", limits={0,inf,0}, pos={x0,y0+2*yinc}, size={145,50}
	SetVariable NM_SetsSkipWaves, value=$( prefixFolder+"SetsSkipWaves" ), fsize=fs, proc=NMSetsPanelVariable
	
	PopupMenu NM_SetsDefineValue, title="value: ", pos={x0+260,y0+1*yinc}, size={0,0}, bodyWidth=50
	PopupMenu NM_SetsDefineValue, mode=1, value="0;1;", proc=NMSetsPanelPopup, fsize=fs
	
	y0 += 145
	
	txt = "Equation"
	
	GroupBox NM_SetsPanelGrp2, title=z_Grp2StrBlank( txt ), pos={x0-20,y0-30}, size={310,90}, fsize=fs
	CheckBox NM_SetsPanelEqOn, title=txt, pos={x0+2,y0-27}, size={16,18}, proc=NMSetsPanelCheckBox, fsize=fs, value=0
	
	PopupMenu NM_SetsArg1, title=" ", pos={x0+90,y0}, size={0,0}, bodyWidth=100, fsize=fs
	PopupMenu NM_SetsArg1, mode=1, value=" ", proc=NMSetsPanelPopup
	
	PopupMenu NM_SetsOp, title=" ", pos={x0+165,y0}, size={0,0}, bodyWidth=65, fsize=fs
	PopupMenu NM_SetsOp, mode=1, value=" ;AND;OR;", proc=NMSetsPanelPopup
	
	PopupMenu NM_SetsArg2, title=" ", pos={x0+275,y0}, size={0,0}, bodyWidth=100, fsize=fs
	PopupMenu NM_SetsArg2, mode=1, value=" ", proc=NMSetsPanelPopup
	
	CheckBox NM_SetsPanelEqLock, title="locked", pos={x0+100,y0+1*yinc-3}, size={16,18}, proc=NMSetsPanelCheckBox, fsize=fs, value=0
	
	x0 = 25
	y0 += 75
	yinc = 35
	
	Button NM_SetsPanelExecute, title="\K("+NMRedStr+")Execute", pos={x0,y0}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelClear, title="Clear", pos={x0+1*xinc,y0}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelInvert, title="Invert", pos={x0+2*xinc,y0}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	
	Button NM_SetsPanelNew, title="New", pos={x0,y0+1*yinc}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelSave, title="Save", pos={x0+1*xinc,y0+1*yinc}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	Button NM_SetsPanelClose, title="Close", pos={x0+2*xinc,y0+1*yinc}, size={90,20}, proc=NMSetsPanelButton, fsize=fs
	
	CheckBox NM_SetsPanelSaveAuto, title="Auto Save", pos={x0+10+1*xinc,y0+2*yinc}, size={16,18}, proc=NMSetsPanelCheckBox, fsize=fs, value=1
	
	NMSetsPanelUpdate( 1 )
	
End // NMSetsPanel

//****************************************************************
//****************************************************************
//****************************************************************

Static Function /S z_Grp2StrBlank( str )
	String str
	
	Variable icnt
	
	String minStr = "                        "
	String outStr = ""
	
	for ( icnt = 0 ; icnt < strlen( str ) ; icnt += 1 )
		outStr += "  "
	endfor
	
	if ( strlen( outStr ) < strlen( minStr ) )
		return minStr
	endif
	
	return outStr
	
End // z_Grp2StrBlank

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelUpdate( updateTable )
	Variable updateTable // ( 0 ) no ( 1 ) yes
	
	Variable numWaves, grpsOn, md, dis, disableAll = 2
	String txt, setList, displayList, parent = "", prefix = ""
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( WinType( NMSetsPanelName ) != 7 )
		NMSetsWavesKill( prefixFolder = prefixFolder )
		return 0
	endif
	
	NMSetsWavesKill( prefixFolder = prefixFolder )
	NMSetsListsToWavesAll( prefixFolder = prefixFolder )
	
	setList = NMSetsPanelList()
	
	displayList = NMSetsDisplayList( prefixFolder = prefixFolder )
	
	grpsOn = NMVarGet( "GroupsOn" )
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )
	
	if ( strlen( prefixFolder ) > 0 )
	
		prefix = NMChild( prefixFolder )
		prefix = ReplaceString( NMPrefixSubfolderPrefix, prefix, "" )
		
		parent = NMParent( prefixFolder )
		parent = NMChild( parent )
	
		CheckNMvar( prefixFolder+"SetsFromWave", 0 )
		CheckNMvar( prefixFolder+"SetsToWave", max( numwaves-1, 0 ) )
		CheckNMvar( prefixFolder+"SetsSkipWaves", 0 )
		
		disableAll = 0
		
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	Variable value = NumVarOrDefault( prefixFolder+"SetsDefineValue", 1 )
	
	Variable fxnOn = NumVarOrDefault( NMDF+"SetsFxnOn", 0 )
	String fxnArg1 = StrVarOrDefault( prefixFolder+"SetsFxnArg1", "" )
	String fxnOp = StrVarOrDefault( prefixFolder+"SetsFxnOp", " " )
	String fxnArg2 = StrVarOrDefault( prefixFolder+"SetsFxnArg2", "" )
	Variable fxnLocked = 0
	
	Variable autoSave = NumVarOrDefault( NMDF+"SetsPanelAutoSave", 1 )
	
	if ( strlen( setName ) == 0 )
		setName = StringFromList( 0, setList )
		SetNMstr( prefixFolder+"SetsDefineSelect", setName )
	endif
	
	if ( IsNMSetLocked( setName, prefixFolder = prefixFolder ) )
		fxnOn = 1
		fxnArg1 = NMSetsEqLockTableFind( setName, "arg1", prefixFolder = prefixFolder )
		fxnOp = NMSetsEqLockTableFind( setName, "op", prefixFolder = prefixFolder )
		fxnArg2 = NMSetsEqLockTableFind( setName, "arg2", prefixFolder = prefixFolder )
		fxnLocked = 1
	endif
	
	DoWindow /T $NMSetsPanelName, "Edit Sets : " + parent + " : " + prefix
	
	md = WhichListItem( setName, NMSetsPanelSelectMenu() )
	
	if ( md >= 0 )
		md += 1
	endif
	
	PopupMenu NM_SetsSelect, win=$NMSetsPanelName, mode=max(md,1), disable=disableAll, value=NMSetsPanelSelectMenu()
	
	if ( fxnOn )
		dis = 2
	endif
	
	dis = z_Disable( dis, disableAll )
	
	GroupBox NM_SetsPanelGrp, win=$NMSetsPanelName, disable=dis
	
	SetVariable NM_SetsFromWave, win=$NMSetsPanelName, disable=dis, value=$( prefixFolder+"SetsFromWave" )
	SetVariable NM_SetsToWave, win=$NMSetsPanelName, disable=dis, value=$( prefixFolder+"SetsToWave" )
	SetVariable NM_SetsSkipWaves, win=$NMSetsPanelName, disable=dis, value=$( prefixFolder+"SetsSkipWaves" )
	
	md = WhichListItem( num2str( value ), "0;1;" )
	
	if ( md >= 0 )
		md += 1
	endif
	
	PopupMenu NM_SetsDefineValue, win=$NMSetsPanelName, mode=max(md,1), value="0;1;", disable=dis
	
	dis = 2
	txt = "Equation"
	
	if ( fxnOn )
		dis = 0
		txt = setName + " ="
	endif
	
	GroupBox NM_SetsPanelGrp2, title=z_Grp2StrBlank( txt )
	CheckBox NM_SetsPanelEqOn, win=$NMSetsPanelName, value=fxnOn, title=txt
	
	md = 1
	
	txt = NMSetsPanelArgMenu()
	
	if ( dis == 0 )
	
		md = WhichListItem( fxnArg1, txt )
		
		if ( md >= 0 )
			md += 1
		endif
	
	endif
	
	PopupMenu NM_SetsArg1, win=$NMSetsPanelName, mode=max(md,1), disable=disableAll, value=NMSetsPanelArgMenu()
	
	md = 1
	
	if ( dis == 0 )
	
		md = WhichListItem( fxnOp, " ;AND;OR;" )
		
		if ( md >= 0 )
			md += 1
		endif
		
	endif
	
	PopupMenu NM_SetsOp, win=$NMSetsPanelName, mode=max(md,1), value=" ;AND;OR;", disable=dis
	
	md = 1
	
	txt = NMSetsPanelArgMenu()
	
	if ( dis == 0 )
	
		md = WhichListItem( fxnArg2, txt )
		
		if ( md >= 0 )
			md += 1
		endif
	
	endif
	
	PopupMenu NM_SetsArg2, win=$NMSetsPanelName, mode=max(md,1), disable=dis, value=NMSetsPanelArgMenu()
	
	CheckBox NM_SetsPanelEqLock, win=$NMSetsPanelName, value=fxnLocked
	
	dis = 0
	
	if ( autoSave )
		dis = 2
	endif
	
	dis = z_Disable( dis, disableAll )
	
	Button NM_SetsPanelExecute, win=$NMSetsPanelName, disable=disableAll
	Button NM_SetsPanelClear, win=$NMSetsPanelName, disable=disableAll
	Button NM_SetsPanelInvert, win=$NMSetsPanelName, disable=disableAll
	
	Button NM_SetsPanelNew, win=$NMSetsPanelName, disable=disableAll
	
	Button NM_SetsPanelSave, win=$NMSetsPanelName, disable=dis
	
	CheckBox NM_SetsPanelSaveAuto, win=$NMSetsPanelName, disable=disableAll, value=autoSave
	
	if ( updateTable )
		NMSetsPanelTable( 1 )
	endif

End // NMSetsPanelUpdate

//****************************************************************
//****************************************************************
//****************************************************************

Static Function z_Disable( dis, disableAll )
	Variable dis, disableAll
	
	if ( ( dis == 2 ) || ( disableAll == 2 ) )
		return 2
	endif
	
	return 0
	
End // z_Disable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelTable( addWavesToTable )
	Variable addWavesToTable // ( 0 ) no ( 1 ) yes
	
	Variable numChannels, ccnt, wcnt, x1 = 350, x2 = 1500, y1 = 0, y2 = 1000
	String wlist, wName, txt, setList
	
	String currentPrefix = CurrentNMWavePrefix()
	
	String tname = NMSetsPanelName + "Table"
	String child = NMSetsPanelName + "#" + tname
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( WinType( NMSetsPanelName ) != 7 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	String arg1 = StrVarOrDefault( prefixFolder+"SetsFxnArg1", "" )
	String arg2 = StrVarOrDefault( prefixFolder+"SetsFxnArg2", "" )
	
	String clist = ChildWindowList( NMSetsPanelName )
	
	if ( WhichListItem( tname, clist ) < 0 )
	
		Edit /Host=$NMSetsPanelName/N=$tname/W=( x1, y1, x2, y2 )
		
	else
	
		setList = NMWindowWaveList( child, 1, 1 )
	
		for ( wcnt = 0; wcnt < ItemsInList( setList ); wcnt += 1 )
			RemoveFromTable /W=$child $StringFromList( wcnt, setList )
		endfor
	
	endif
	
	ModifyTable /W=$child title( Point )= currentPrefix
	
	if ( !addWavesToTable )
		return 0
	endif
	
	setList = AddListItem( setName, "", ";", inf )
	
	if ( StringMatch( arg1[0,4], "Group" ) )
		arg1 = "" // "Group"
	elseif ( StringMatch( arg2[0,4], "Group" ) )
		arg2 = "" // "Group"
	endif
	
	if ( strlen( arg1 ) > 0 )
		setList = AddListItem( arg1, setList, ";", inf )
	endif
	
	if ( strlen( arg2 ) > 0 )
		setList = AddListItem( arg2, setList, ";", inf )
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( setList ) ; wcnt += 1 )
	
		setName = prefixfolder + StringFromList( wcnt, setList )
		
		if ( WaveExists( $setName ) )
			AppendToTable /W=$child $setName
		endif
	
	endfor
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
	
		wName = NMChanWaveListName( ccnt, prefixFolder = prefixFolder )
		
		if ( WaveExists( $wName ) )
			AppendToTable /W=$child $wName
			ModifyTable /W=$child width($wName)=100
		endif
	
	endfor
	
	return 0

End // NMSetsPanelTable

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelSelectMenu()

	String setList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
	
		setList = NMSetsPanelList()
		
		if ( ItemsInList( setList ) > 0 )
			return " ;" + setList
		endif
	
	endif

	return " "

End // NMSetsPanelSelectMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelArgMenu()

	String setList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) > 0 )
	
		setList = NMSetsPanelList() + NMGroupsList( 1, prefixFolder = prefixFolder )
	
		if ( ItemsInList( setList ) > 0 )
			return " ;" + setList
		endif
		
	endif

	return " "

End // NMSetsPanelArgMenu

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	if ( !CheckCurrentFolder() )
		return 0
	endif
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMSetsPanelFxnCall( fxn, "" )
	
End // NMSetsPanelVariable

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelButton( ctrlName ) : ButtonControl
	String ctrlName
	
	if ( !CheckCurrentFolder() )
		return 0
	endif
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )

	NMSetsPanelFxnCall( fxn, "" )
	
End // NMSetsPanelButton

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelPopup( ctrlName, popNum, popStr ) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	if ( !CheckCurrentFolder() )
		return 0
	endif
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMSetsPanelFxnCall( fxn, popStr )

End // NMSetsPanelPopup

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	if ( !CheckCurrentFolder() )
		return 0
	endif
	
	String fxn = ReplaceString( "NM_", ctrlName, "" )
	
	NMSetsPanelFxnCall( fxn, num2istr( checked ) )

End // NMSetsPanelCheckBox

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelHook( s )
	STRUCT WMWinHookStruct &s
	
	String tname = NMSetsPanelName + "Table"
	
	Variable autoSave = NumVarOrDefault( NMDF+"SetsPanelAutoSave", 1 )
	
	String win = s.winName
	Variable event = s.eventCode
	
	GetWindow $win activeSW
	
	String activeSubwindow = S_value
	
	if ( StringMatch( s.eventName, "kill" ) )
	
		if ( NumVarOrDefault( NMDF+"SetsPanelChange", 0 ) == 1 )
		
			if ( autoSave )
			
				NMSetsPanelSave()
			
			else
			
				DoAlert 1, "Save changes to your current Sets?"
			
				if ( V_flag == 1 )
					NMSetsPanelSave()
				endif
			
			endif
			
		endif
		
		NMSetsWavesKill()
		
		return 0
		
	endif
	
	if ( ( NumVarOrDefault( NMDF+"SetsPanelChange", 0 ) == 1 ) && autoSave )
		NMSetsPanelSave()
		return 0
	endif
	
	if ( strsearch( activeSubwindow, tname, 0, 2 ) > 0 )
	
		if ( StringMatch( s.eventName, "keyboard" ) && ( s.keycode == 13 ) ) // user hit "enter" in table
			SetNMvar( NMDF+"SetsPanelChange", 1 )
		endif
		
	endif
	
	return 0

End // NMSetsPanelHook

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelFxnCall( fxn, select )
	String fxn, select
	
	Variable snum = str2num( select )
	
	strswitch( fxn )
	
		case "SetsSelect":
			return NMSetsPanelSelect( select )
		
		case "SetsFromWave":
		case "SetsToWave":
		case "SetsSkipWaves":
			break
	
		case "SetsDefineValue":
			return NMSetsPanelValue( snum )
			
		case "SetsPanelEqOn":
			return NMSetsPanelEqOn( snum )
			
		case "SetsOp":
			return NMSetsPanelEqOp( select )
			
		case "SetsArg1":
			return NMSetsPanelEqArg1( select )
			
		case "SetsArg2":
			return NMSetsPanelEqArg2( select )
			
		case "SetsPanelEqLock":
			return NMSetsPanelEqLock( snum )
			
		case "SetsPanelExecute":
			return SetsPanelExecute()
			
		case "SetsPanelClear":
			return NMSetsPanelClear()
			
		case "SetsPanelInvert":
			return NMSetsPanelInvert()
	
		case "SetsPanelNew":
			return strlen( NMSetsPanelNew( 0 ) )
			
		//case "SetsPanelCopy":
		//	return strlen( NMSetsPanelNew( 1 ) )
			
		case "SetsPanelSaveAuto":
			return NMSetsPanelSaveAutoToggle()
			
		case "SetsPanelSave":
			return NMSetsPanelSave()
			
		case "SetsPanelClose":
			return NMSetsPanelClose()
			
	endswitch
	
	return -1

End // NMSetsPanelFxnCall

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelSelect( setName )
	String setName // ( "" ) for current
	
	String setList
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	setList = NMSetsPanelList()
	
	if ( WinType( NMSetsPanelName ) != 7 )
		return -1
	endif
	
	if ( WhichListItem( setName, setList ) < 0 )
		setName = ""
	endif
	
	SetNMstr( prefixFolder+"SetsDefineSelect", setName )
	
	NMSetsPanelUpdate( 1 )
	
End // NMSetsPanelSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelValue( value )
	Variable value
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	SetNMvar( prefixFolder+"SetsDefineValue", value )
	
	NMSetsPanelUpdate( 0 )
	
	return 0
	
End // NMSetsPanelValue

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelEqOn( value )
	Variable value
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	if ( IsNMSetLocked( setName, prefixFolder = prefixFolder ) )
		
		DoAlert 0, setName + " is currently locked by an equation. To remove lock uncheck the " + NMQuotes( "locked" ) + " checkbox."
		
	else
	
		if ( value > 0 )
			SetNMvar( NMDF+"SetsFxnOn", 1 )
		else
			SetNMvar( NMDF+"SetsFxnOn", 0 )
		endif
	
	endif
	
	NMSetsPanelUpdate( 1 )
	
	return 0
	
End // NMSetsPanelEqOn

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelEqOp( op )
	String op
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	SetNMstr( prefixFolder+"SetsFxnOp", op )
	
	NMSetsPanelUpdate( 1 )
	
	return 0
	
End // NMSetsPanelEqOp

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelEqArg1( arg )
	String arg
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( StringMatch( arg, " " ) )
		arg = ""
	endif
	
	SetNMstr( prefixFolder+"SetsFxnArg1", arg )
	
	NMSetsPanelUpdate( 1 )
	
	return 0
	
End // NMSetsPanelEqArg1

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelEqArg2( arg )
	String arg
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( StringMatch( arg, " " ) )
		arg = ""
	endif
	
	SetNMstr( prefixFolder+"SetsFxnArg2", arg )
	
	NMSetsPanelUpdate( 1 )
	
	return 0
	
End // NMSetsPanelEqArg2

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelEqLock( on )
	Variable on
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	if ( on )
	
		return NMSetsPanelFunction( 1 )
		
	else
	
		NMSetsEqLockTableClear( setName, prefixFolder = prefixFolder )
		UpdateNMPanelSets( 1 )
	
	endif
	
	NMSetsPanelUpdate( 1 )
	
	return 0

End // NMSetsPanelEqLock

//****************************************************************
//****************************************************************
//****************************************************************

Function SetsPanelExecute()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	Variable fxnOn = NumVarOrDefault( NMDF+"SetsFxnOn", 0 )
	Variable locked = NumVarOrDefault( prefixFolder+"SetsFxnLocked", 1 )
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	if ( fxnOn )
	
		locked += 1
		
		Prompt locked, " ", popup "execute this equation once only;lock this equation;"
		
		DoPrompt "Sets Equation", locked
		
		if ( V_flag == 1 )
			return -1 // cancel
		endif
		
		locked -= 1
		
		SetNMvar( prefixFolder+"SetsFxnLocked", locked )
	
		return NMSetsPanelFunction( locked )
		
	else
	
		return NMSetsPanelDefine()
		
	endif

End // SetsPanelExecute

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelDefine()

	Variable wlimit
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	Variable first = NumVarOrDefault( prefixFolder+"SetsFromWave", Nan )
	Variable last = NumVarOrDefault( prefixFolder+"SetsToWave", Nan )
	Variable skip = NumVarOrDefault( prefixFolder+"SetsSkipWaves", 0 )
	Variable value = NumVarOrDefault( prefixFolder+"SetsDefineValue", 1 )
	
	Variable autoSave = NumVarOrDefault( NMDF+"SetsPanelAutoSave", 1 )
	
	if ( !WaveExists( $prefixFolder+setName ) )
		return -1
	endif
	
	wlimit = numpnts( $prefixFolder+setName ) - 1
	
	first = max( first, 0 )
	first = min( first, wlimit )
	
	last = max( last, 0 )
	last = min( last, wlimit )
	
	skip = max( skip, 0 )
	skip = min( skip, wlimit )
	
	if ( numtype( skip ) > 0 )
		skip = 0
	endif
	
	if ( numtype( first * last * skip ) > 0 )
		NMDoAlert( "Abort NMSetsPanelDefine: wave number out of bounds." )
		return -1
	endif
	
	Wave wtemp = $prefixFolder+setName
	
	wtemp[first,last;abs( skip )+1] = value
	
	SetNMvar( NMDF+"SetsPanelChange", 1 )
	
	if ( autoSave )
		NMSetsPanelSave()
	endif

End // NMSetsPanelDefine

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelFunction( locked )
	Variable locked

	Variable wcnt, grp1 = Nan, grp2 = Nan
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	String arg1 = StrVarOrDefault( prefixFolder+"SetsFxnArg1", "" )
	String op = StrVarOrDefault( prefixFolder+"SetsFxnOp", " " )
	String arg2 = StrVarOrDefault( prefixFolder+"SetsFxnArg2", "" )
	
	Variable autoSave = NumVarOrDefault( NMDF+"SetsPanelAutoSave", 1 )
	
	String setList = NMSetsList( prefixFolder = prefixFolder ) + NMGroupsList( 1, prefixFolder = prefixFolder )
	
	if ( StringMatch( op, " " ) )
		arg2 = " "
	endif
	
	if ( !WaveExists( $prefixFolder+setName ) )
		return -1
	endif
	
	if ( StringMatch( arg1[0,4], "Group" ) )
		grp1 = str2num( arg1[5,inf] )
	endif
	
	if ( StringMatch( arg2[0,4], "Group" ) )
		grp2 = str2num( arg2[5,inf] )
	endif
	
	Wave wtemp = $prefixFolder+setName
	
	if ( !StringMatch( setName, arg1 ) )
	
		if ( numtype( grp1 ) == 0 )
		
			for ( wcnt = 0 ; wcnt < numpnts( wtemp ) ; wcnt += 1 )
				wtemp[ wcnt ] = ( NMGroupsNum( wcnt, prefixFolder = prefixFolder ) == grp1 )
			endfor
	
		elseif ( WaveExists( $prefixFolder+arg1 ) )
	
			Wave warg = $prefixFolder+arg1
		
			wtemp = warg
			
		else
		
			return -1
			
		endif
		
	endif
	
	if ( strlen( arg2 ) > 0 ) 
	
		if ( numtype( grp2 ) == 0 )
		
			for ( wcnt = 0 ; wcnt < numpnts( wtemp ) ; wcnt += 1 )
			
				strswitch( op )
			
					case "AND":
						wtemp[ wcnt ] = ( wtemp[ wcnt ] && ( NMGroupsNum( wcnt, prefixFolder = prefixFolder ) == grp2 ) )
						break
				
					case "OR":
						wtemp[ wcnt ] = ( wtemp[ wcnt ] || ( NMGroupsNum( wcnt, prefixFolder = prefixFolder ) == grp2 ) )
						break
			
				endswitch
			
			endfor
		
		elseif ( WaveExists( $prefixFolder+arg2 ) )
	
			Wave warg = $prefixFolder+arg2
		
			strswitch( op )
			
				case "AND":
					wtemp = wtemp && warg
					break
			
				case "OR":
					wtemp = wtemp || warg
					break
			
			endswitch
		
		else
		
			return -1
			
		endif
		
	endif
	
	SetNMvar( NMDF+"SetsPanelChange", 1 )
	
	if ( locked )
		NMSetsEqLockTableAdd( setName, arg1, op, arg2, prefixFolder = prefixFolder )
	endif
	
	if ( autoSave )
		NMSetsPanelSave()
	endif
	
	NMSetsPanelUpdate( 1 )
	
	return 0

End // NMSetsPanelFunction

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelClear()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	Variable autoSave = NumVarOrDefault( NMDF+"SetsPanelAutoSave", 1 )
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( strlen( setName ) == 0 ) || !WaveExists( $prefixFolder + setName ) )
		return -1
	endif
	
	Wave wtemp = $prefixFolder + setName
	
	wtemp = 0
	
	SetNMvar( NMDF+"SetsPanelChange", 1 )
	
	NMSetsEqLockTableClear( setName, prefixFolder = prefixFolder )
	
	if ( autoSave )
		NMSetsPanelSave()
	endif
	
	NMSetsPanelUpdate( 1 )
	
	return 0

End // NMSetsPanelClear

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelInvert()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setName = StrVarOrDefault( prefixFolder+"SetsDefineSelect", "" )
	
	Variable autoSave = NumVarOrDefault( NMDF+"SetsPanelAutoSave", 1 )
	
	if ( ( strlen( prefixFolder ) == 0 ) || ( strlen( setName ) == 0 ) || !WaveExists( $prefixFolder + setName ) )
		return -1
	endif
	
	if ( IsNMSetLocked( setName, prefixFolder = prefixFolder ) )
	
		DoAlert 1, setName + " is locked by an equation. Do you want to clear this equation and continue?"
	
		if ( V_flag == 1 )
			NMSetsEqLockTableClear( setName, prefixFolder = prefixFolder )
		else
			return -1
		endif
	
	endif
	
	Wave wtemp = $prefixFolder + setName
	
	wtemp = !wtemp
	
	SetNMvar( NMDF+"SetsPanelChange", 1 )
	
	if ( autoSave )
		NMSetsPanelSave()
	endif
	
	NMSetsPanelUpdate( 1 )

End // NMSetsPanelInvert

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelNameNext()
	
	Variable icnt
	String setName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	for ( icnt = 1; icnt < 99; icnt += 1 )
	
		setName = "Set" + num2istr( icnt )
		
		if ( !AreNMSets( setName, prefixFolder = prefixFolder ) && !AreNMSetsWaves( setName, prefixFolder = prefixFolder ) )
			return setName
		endif
		
	endfor

	return ""
	
End // NMSetsNamePanelNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelNewNameAsk()

	String setName = NMSetsPanelNameNext()
	
	Prompt setName, "enter new set name:"
	DoPrompt "New Sets", setName

	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return setName
	
End // NMSetsPanelNewNameAsk

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMSetsPanelNew( copyFlag )
	Variable copyFlag // copy currently select Set to new Set ( 0 ) no ( yes )
	
	Variable numWaves
	String setName, newName
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return ""
	endif
	
	Variable autoSave = NumVarOrDefault( NMDF+"SetsPanelAutoSave", 1 )
	
	newName = NMSetsPanelNewNameAsk()
	
	if ( strlen( newName ) == 0 )
		return "" // cancel
	endif
	
	if ( WaveExists( $prefixFolder+newName ) )
		NMDoAlert( "Abort NMSetsPanelNew: Set already exists: " + newName )
		return ""
	endif
	
	numWaves = NumVarOrDefault( prefixFolder + "NumWaves", 0 )

	Make /B/U/O/N=( numWaves ) $prefixFolder+newName = 0
	
	NMSetsWavesTag( prefixFolder+newName, prefixFolder = prefixFolder )
	
	if ( copyFlag )
	
		setName = StrVarOrDefault( NMDF+"SetsDefineSelect", "" )
		
		if ( ( strlen( setName ) > 0 ) && WaveExists( $prefixFolder+setName ) && WaveExists( $prefixFolder+newName ) )
		
			Wave newWave = $prefixFolder+newName
			Wave selectWave = $prefixFolder+setName
			
			newWave = selectWave
			
		endif
	
	endif
	
	SetNMstr( prefixFolder+"SetsDefineSelect", newName )
	
	SetNMvar( NMDF+"SetsPanelChange", 1 )
	
	if ( autoSave )
		NMSetsPanelSave()
	endif
	
	NMSetsPanelUpdate( 1 )
	
	return newName

End // NMSetsPanelNew

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelClose()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	DoWindow /K $NMSetsPanelName
	
	NMSetsWavesKill( prefixFolder = prefixFolder )
	UpdateNMPanelSets( 1 )
	
	return 0

End // NMSetsPanelClose

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelSaveAutoToggle()

	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif

	Variable on = NumVarOrDefault( NMDF+"SetsPanelAutoSave", 1 )
	
	on = BinaryInvert( on )
	
	SetNMvar( NMDF+"SetsPanelAutoSave", on )
	
	NMSetsPanelUpdate( 0 )
	
	return on
	
End // NMSetsPanelSaveAuto

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsPanelSave()
	
	String prefixFolder = CurrentNMPrefixFolder()
	
	if ( strlen( prefixFolder ) == 0 )
		return -1
	endif
	
	String setList = NMSetsPanelList()
	
	if ( NumVarOrDefault( NMDF+"SetsPanelChange", 0 ) == 0 )
		return 0 // nothing to do
	endif
	
	NMSetsKill( setList, prefixFolder = prefixFolder, update = 0 )
	NMSetsWavesToLists( setList, prefixFolder = prefixFolder )
	
	NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
	NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
	UpdateNMPanelSets( 1 )
	
	SetNMvar( NMDF+"SetsPanelChange", 0 )
	
	return 0

End // NMSetsPanelSave

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsFxnFilter( n1, n2, grp, operation ) // NOT USED
	Variable n1, n2, grp
	String operation // see strswitch below
	
	//NMDeprecated( "NMSetsFxnFilter", "NMSetsEquationFilter" )
	
	strswitch( operation )
	
		case "AND":
		case "&":
		case "&&":
			if ( grp == -1 )
				return n1 && n2
			else
				return n1 && NMGroupFilter( n2, grp )
			endif
			break
			
		case "OR":
		case "|":
		case "||":
			if ( grp == -1 )
				return n1 || n2
			else
				return n1 || ( NMGroupFilter( n2, grp ) )
			endif
			break
			
		case "EQUALS":
		case "=":
			if ( grp == -1 )
				return n2
			else
				return NMGroupFilter( n2, grp )
			endif
			break
			
		default:
			return 0
	
	endswitch
	
End // NMSetsFxnFilter

//****************************************************************
//****************************************************************
//****************************************************************

Function NMSetsToggle( setList [ waveNum, prefixFolder, update, history ] ) // NOT USED
	String setList // set name list, or "All"
	Variable waveNum // ( -1 ) for current
	String prefixFolder
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable scnt, ccnt, rvalue, value = 1
	Variable numChannels
	String wName, wList, setName
	
	if ( ItemsInList( setList ) == 0 )
		return 0
	endif
	
	String vlist = NMCmdStr( setList, "" )
	
	if ( ParamIsDefault( waveNum ) )
		waveNum = NumVarOrDefault( prefixFolder + "CurrentWave", 0 )
	else
		vlist = NMCmdNumOptional( "waveNum", waveNum, vlist, integer = 1 )
	endif
	
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
	
	if ( StringMatch( setList, "All" ) )
		setList = NMSetsList()
	endif
	
	numChannels = NumVarOrDefault( prefixFolder + "NumChannels", 0 )
	
	for ( scnt = 0 ; scnt < ItemsInList( setList ) ; scnt += 1 )
	
		setName = StringFromList( scnt, setList )
	
		for ( ccnt = 0 ; ccnt < numChannels ; ccnt += 1 )
		
			wName = NMChanWaveName( ccnt, waveNum, prefixFolder = prefixFolder )
			wList = NMSetsWaveList( setName, ccnt, prefixFolder = prefixFolder )
	
			if ( WhichListItem( wName, wList ) >= 0 )
				value = 0 // remove from list
			endif
			
		endfor
		
		rvalue += NMSetsDefine( setName, value, waveNum, waveNum, 0, 0, prefixFolder = prefixFolder, update = 0 )
	
	endfor
	
	if ( update && ( rvalue >= 0 ) )
		NMSetsEqLockTableUpdate( prefixFolder = prefixFolder )
		NMWaveSelectListMaster( prefixFolder = prefixFolder, updateNM = 1 )
		UpdateNMPanelSets( 1 )
	endif
	
	if ( NMVarGet( "SetsAutoAdvance" ) ) 
		NMNextWave( +1 )
	endif
	
	return 0

End // NMSetsToggle

//****************************************************************
//****************************************************************
//****************************************************************
