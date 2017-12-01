#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma hide = 1

Static StrConstant OldEventTableSelect = "Event Table "

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
//	Spontaneous Event Detection
//
//	NM tab entry "Event"
//
//	Table functions with old format.
//	Event functions not used anymore.
//
//****************************************************************
//****************************************************************

Function NMEventTableOldExists()

	Variable icnt, seqNum
	String wName

	String wList = WaveList( "EV_ThreshT_*" , ";", "Text:0" ) // old wave names that reside in current data folder
	
	if ( ItemsInList( wList ) > 0 )
	
		for ( icnt = 0 ; icnt < ItemsInList( wList ) ; icnt += 1 )
		
			wName = StringFromList( icnt, wList )
			wName = ReplaceString( "EV_ThreshT_", wName, "" )
			
			if ( strsearch( wName, "_", 0 ) < 0 )
				return 1
			endif
			
		endfor
		
	endif

	return 0
	
End // NMEventTableOldExists

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldName( chanNum, tableNum )
	Variable chanNum
	Variable tableNum
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ( numtype( tableNum ) == 0 ) && ( tableNum >= 0 ) )
		return "EV_" + CurrentNMFolderPrefix() + "Table" + "_" + ChanNum2Char( chanNum ) + num2istr( tableNum )
	endif
	
	return ""

End // NMEventTableOldName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldSelect( chanNum, tableNum ) // e.g. "Event Table A0"
	Variable chanNum
	Variable tableNum
	
	chanNum = ChanNumCheck( chanNum )

	if ( ( numtype( tableNum ) > 0 ) || ( tableNum < 0 ) )
		return ""
	endif

	return OldEventTableSelect + ChanNum2Char( chanNum ) + num2istr( tableNum )

End // NMEventTableOldSelect

//****************************************************************
//****************************************************************
//****************************************************************

Function CurrentNMEventTableOldFormat()
	
	return NMEventTableOldFormat( StrVarOrDefault( "EventTableSelected", "" ) )

End // CurrentNMEventTableOldFormat

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableOldFormat( tableTitle )
	String tableTitle
	
	if ( StrSearch( tableTitle, OldEventTableSelect, 0, 2 ) == 0 )
		return 1
	else
		return 0
	endif
	
End // NMEventTableOldFormat

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableOldNum()

	Variable tableNum, items
	String tableSelect, tableName, tableList
	
	if ( NMEventTableOldExists() )
	
		tableSelect = StrVarOrDefault( "EventTableSelected", "" )
	
		if ( NMEventTableOldFormat( tableSelect ) )
		
			tableNum = EventNumFromName( tableSelect )
			
			if ( ( numtype( tableNum ) == 0 ) && ( tableNum >= 0 ) )
				return tableNum
			endif
			
		endif
		
	endif
	
	return -1

End // NMEventTableOldNum

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventTableOldNumNext()

	Variable icnt, jcnt, tableNum, found

	String tableList = NMEventTableOldNumList( CurrentNMChannel() )
	
	if ( ItemsInList( tableList ) == 0 )
		return 0
	endif
	
	for ( icnt = 0 ; icnt < 50 ; icnt += 1 )
	
		found = 0
	
		for ( jcnt = 0 ; jcnt < ItemsInList( tableList ) ; jcnt += 1 )
		
			tableNum = str2num( StringFromList( jcnt, tableList ) )
			
			if ( tableNum == icnt )
				found = 1
				break
			endif
		
		endfor
		
		if ( !found )
			return icnt
		endif
	
	endfor

End // NMEventTableOldNumNext

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldListAll() // e.g. "Event Table A0;Event Table A1;"
	
	Variable ccnt, cbgn, cend = NMNumChannels()
	String tableList = ""
	
	for ( ccnt = cbgn ; ccnt <= cend ; ccnt += 1 )
		tableList = NMAddToList( NMEventTableOldList( ccnt ), tableList, ";" )
	endfor
	
	return tableList
	
End // NMEventTableOldListAll

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldList( chanNum ) // e.g. "Event Table A0;Event Table A1;"
	Variable chanNum // -1 for all
	
	Variable icnt, seqNum
	String chanChar, wName, wList, tableList = ""
	
	chanNum = ChanNumCheck( chanNum )
	chanChar = ChanNum2Char( chanNum )
	
	String prefix = "EV_ThreshT_" + chanChar
	
	wList = WaveList( prefix + "*" , ";", "Text:0" )
		
	for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		
		seqNum = GetSeqNum( wName )
		
		if ( numtype( seqNum ) > 0 )
			continue
		endif
		
		tableList = NMAddToList( OldEventTableSelect + chanChar + num2str( seqNum ), tableList, ";" )
		
	endfor
	
	return tableList

End // NMEventTableOldList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldNumList( chanNum ) // e.g. "0;1;2;"
	Variable chanNum
	
	Variable icnt
	String prefix, wName, wList, tableNumStr, tableList = ""
	
	chanNum = ChanNumCheck( chanNum )
	
	prefix = "EV_ThreshT_" + ChanNum2Char( chanNum )
	
	wList = WaveList( prefix + "*" , ";", "Text:0" )
	
	if ( ItemsInList( wList ) == 0 )
		return ""
	endif
	
	for ( icnt = 0; icnt < ItemsInList( wList ); icnt += 1 )
	
		wName = StringFromList( icnt, wList )
		tableNumStr = ReplaceString( prefix, wName, "" )
		
		if ( numtype( str2num( tableNumStr ) ) == 0 )
			tableList = NMAddToList( tableNumStr, tableList, ";" )
		endif
		
	endfor
	
	return tableList

End // NMEventTableOldNumList

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldWaveName( wtype, chanNum, tableNum ) // e.g. ""
	String wtype
	Variable chanNum
	Variable tableNum
	String wavePrefix
	
	if ( strlen( wtype ) == 0 )
		return ""
	endif
	
	chanNum = ChanNumCheck( chanNum )
	
	if ( ( numtype( tableNum ) > 0 ) || ( tableNum < 0 ) )
		return ""
	endif
	
	String wname = "EV_" + wtype + "_" + ChanNum2Char( chanNum ) + num2istr( tableNum )
		
	return wname[ 0,30 ]
	
End // NMEventTableOldWaveName

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableNew( [ history ] )
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	Variable tableNum
	String tableSelect, tableName
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	if ( NMEventTableOldExists() ) // create old format table only
	
		NMOutputListsReset()
	
		tableNum = NMEventTableOldNumNext()
		tableSelect = NMEventTableOldSelect( CurrentNMChannel(), tableNum )
		
		tableName = NMEventTableSelect( tableSelect )
		
		SetNMstr( NMDF + "OutputWinList", tableName )
		
		NMHistoryOutputWindows()
		
		return tableName
	
	endif
	
	return ""

End // NMEventTableNew

//****************************************************************
//****************************************************************
//****************************************************************

Function /S NMEventTableOldWaveList()

	Variable wcnt
	String wname, outList = ""

	String wList = WaveList( "EV_ThreshT_*", ";", "Text:0" )
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
	
		wname = StringFromList( wcnt, wList )
		
		if ( ( strsearch( wname, "intvl", 0, 2 ) < 0 ) && ( strsearch( wname, "hist", 0, 2 ) < 0 ) )
			outList = NMAddToList( wname, outList, ";" )
		endif
		
	endfor
	
	return outList

End // NMEventTableOldWaveList

//****************************************************************
//****************************************************************
//****************************************************************
//
//	Functions Not Used Anymore
//
//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMEventVarGet( varName, value ) // NOT USED
	String varName
	Variable value
	
	String df = NMEventDF
	
	if ( strlen( varName ) == 0 )
		return NM2Error( 21, "varName", varName )
	endif
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "EventDF", df )
	endif
	
	Variable /G $df+varName = value
	
	return 0
	
End // SetNMEventVar

//****************************************************************
//****************************************************************
//****************************************************************

Function SetNMEventStrGet( strVarName, strValue ) // NOT USED
	String strVarName
	String strValue
	
	String df = NMEventDF
	
	if ( strlen( strVarName ) == 0 )
		return NM2Error( 21, "strVarName", strVarName )
	endif
	
	if ( !DataFolderExists( df ) )
		return NM2Error( 30, "EventDF", df )
	endif
	
	String /G $df+strVarName = strValue
	
	return 0
	
End // SetNMEventStr

//****************************************************************
//****************************************************************
//****************************************************************

Function NMEventOverWrite() // NOT USED

	return 1
	
End // NMEventOverWrite

//****************************************************************
//****************************************************************
//****************************************************************

Function EventAutoAdvanceCall() // NOT USED

	Variable findNextSelect, searchSelect, reviewSelect
	
	Variable reviewFlag = NMEventVarGet( "ReviewFlag" )
	
	Variable findNext = NMEventVarGet( "FindNextAfterSaving" )
	Variable search = NMEventVarGet( "SearchWaveAdvance" )
	Variable review = NMEventVarGet( "ReviewWaveAdvance" )
	
	findNextSelect = findNext + 1
	searchSelect = search + 1
	reviewSelect = review + 1
	
	Prompt findNextSelect, "automatically search for next event after saving?", popup "no;yes;"
	Prompt searchSelect, "automatically advance to next/previous wave when searching?", popup "no;yes;"
	Prompt reviewSelect, "automatically advance to next/previous wave when reviewing?", popup "no;yes;"
	
	if ( reviewFlag )
		DoPrompt "Event Auto Advance", reviewSelect
	else
		DoPrompt "Event Auto Advance", findNextSelect, searchSelect, reviewSelect
	endif

	if ( V_flag == 1 )
		UpdateEventTab()
		return 0 // cancel
	endif
	
	findNextSelect -= 1
	searchSelect -= 1
	reviewSelect -= 1
	
	if ( findNextSelect != findNext )
		NMConfigVarSet( "Event" , "FindNextAfterSaving" , BinaryCheck( findNext ) )
	endif
	
	if ( searchSelect != search )
		NMConfigVarSet( "Event" , "SearchWaveAdvance" , BinaryCheck( searchSelect ) )
	endif
	
	if ( reviewSelect != review )
		NMConfigVarSet( "Event" , "ReviewWaveAdvance" , BinaryCheck( reviewSelect ) )
	endif
	
	return 0
	
End // EventAutoAdvanceCall

//****************************************************************
//****************************************************************
//****************************************************************

Function /S EventWaveList( tableNum ) // NOT USED
	Variable tableNum

	Variable icnt
	String wName, wList, wRemove, tableNumStr = num2istr( tableNum )
	
	if ( tableNum == -1 )
		tableNumStr = ""
	endif
	
	wList = WaveList( "EV_*T_*" + tableNumStr, ";", "Text:0" )
	wRemove = WaveList( "EV_Evnt*", ";", "Text:0" )
	wRemove += WaveList( "EV_*intvl*", ";", "Text:0" )
	wRemove += WaveList( "EV_*hist*", ";", "Text:0" )
	
	for ( icnt = 0; icnt < ItemsInList( wRemove ); icnt += 1 )
		wName = StringFromList( icnt, wRemove )
		wList = RemoveFromList( wName, wList )
	endfor

	for ( icnt = ItemsInList( wList ) - 1; icnt >= 0; icnt -= 1 )
	
		wName = StringFromList( icnt, wList )
		
		WaveStats /Q/Z $wName
		
		if ( V_numNans == numpnts( $wName ) )
			wList = RemoveFromList( wName, wList )
		endif
		
	endfor
	
	return wList

End // EventWaveList

//****************************************************************
//****************************************************************
//****************************************************************
