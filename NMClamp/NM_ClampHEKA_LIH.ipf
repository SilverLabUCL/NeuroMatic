#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//****************************************************************
//****************************************************************

Function /S NM_LIH_InterfaceNumList()
	return "0;1;2;3;10;11;"
End

//****************************************************************
//****************************************************************

Function /S NM_LIH_InterfaceNameList()
	return "ITC16;ITC18;ITC1600;LIH8p8;ITC16USB;ITC18USB;"
End

//****************************************************************
//****************************************************************

Function NM_LIH_InitInterface()

	Variable icnt, error = -1, boardNum
	String boardName, errMsg = ""
	
	String boardNumList = NM_LIH_InterfaceNumList()
	
	for ( icnt =  0 ; icnt < ItemsInList( boardNumList ) ; icnt += 1 )
		
		boardNum = str2num( StringFromList( icnt, boardNumList ) )
		
		//error = LIH_InitInterface( errMsg, boardNum )
		
		if ( error == 0 )
			return boardNum
		endif
		
	endfor
	
	return -1

End // NM_LIH_InitInterface

//****************************************************************
//****************************************************************

Function /S NM_LIH_InitInterfaceName()

	String boardName
	String cdf = NMClampDF

	Variable boardNum = NM_LIH_InitInterface()
	String boardNumList = NM_LIH_InterfaceNumList()
	String boardNameList = NM_LIH_InterfaceNameList()
	
	if ( boardNum < 0 )
		return ""
	endif
	
	String boardNumStr = num2istr( boardNum )
	
	Variable item = WhichListItem( boardNumStr, boardNumList )

	if ( item < 0 )
		return ""
	endif
	
	boardName = StringFromList( item, boardNameList )
	
	SetNMstr( cdf+"BoardList", boardName )
	
	return boardName
	
End // NM_LIH_InitInterfaceName

//****************************************************************
//****************************************************************

Function NM_LIH_Config() // called from ClampAcquireManager

	Print "NM_LIH_Config"

End // NM_LIH_Config

//****************************************************************
//****************************************************************

Function NM_LIH_Acquire( callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime ) // called from ClampAcquireManager
	Variable callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime
	
	Print "NM_LIH_Acquire", callmode, savewhen, WaveLength, NumStimWaves, interStimTime, NumStimReps, interRepTime
	
End // NM_LIH_Acquire

//****************************************************************
//****************************************************************