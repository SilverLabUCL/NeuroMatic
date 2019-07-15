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

Static Constant NumWavesDefault = 1
Static Constant DeltaxDefault = 0.1
Static Constant WaveLengthDefault = 100
Static StrConstant WavePrefixDefault = "Pulse"

//****************************************************************
//****************************************************************

Function /S NMTabPrefix_Pulse() // this function allows NM to determine tab name and prefix

	return "PU_"

End // NMTabPrefix_Pulse

//****************************************************************
//****************************************************************

Function NMPulseSubfolderExists()

	String sf, wavePrefix

	if ( exists( "CurrentPrefixPulse" ) == 2 )
	
		wavePrefix = StrVarOrDefault( "CurrentPrefixPulse", "" )
		
		if ( strlen( wavePrefix ) == 0 )
			return 0
		endif
		
		sf = CurrentNMFolder( 1 ) + "Pulse_" + wavePrefix  + ":"
			
		if ( DataFolderExists( sf ) )
			return 1
		endif
		
	endif

	return 0
	
End // NMPulseSubfolderExists

//****************************************************************
//****************************************************************

Function /S NMPulseDF() // data folder where tab globals are stored

	if ( NMPulseSubfolderExists() )
		return CurrentNMFolder( 1 )
	else
		return NMPulseDF
	endif

End // NMPulseDF

//****************************************************************
//****************************************************************

Function /S NMPulseSubfolder()

	String sf, wavePrefix
	
	if ( exists( "CurrentPrefixPulse" ) == 2 )
	
		wavePrefix = StrVarOrDefault( "CurrentPrefixPulse", "" )
		
		if ( strlen( wavePrefix ) > 0 )
		
			sf = CurrentNMFolder( 1 ) + "Pulse_" + wavePrefix  + ":"
			
			if ( DataFolderExists( sf ) )
				return sf // found a pulse subfolder
			endif
			
		endif
		
	endif
	
	wavePrefix = StrVarOrDefault( NMPulseDF + "CurrentPrefixPulse", "" )
	
	if ( strlen( wavePrefix ) == 0 )
		SetNMstr( NMPulseDF + "CurrentPrefixPulse", WavePrefixDefault )
		wavePrefix = WavePrefixDefault
	endif

	return NMPulseDF + "Pulse_" + wavePrefix  + ":"

End // NMPulseSubfolder

//****************************************************************
//****************************************************************

Function /S NMPulseSubfolderList( [ df, fullPath ] )
	String df
	Variable fullPath
	
	String fList
	String folderPrefix = "Pulse_"
	
	if ( ParamIsDefault( df ) || ( strlen( df ) == 0 ) )
		df = NMPulseDF()
	elseif ( !DataFolderExists( df ) )
		return NM2ErrorStr( 30, "df", df )
	endif
	
	return NMSubfolderList( folderPrefix, df, fullPath )

End // NMPulseSubfolderList

//****************************************************************
//****************************************************************

Static Function /S z_NMPulseWavePrefixNewCall()

	String wavePrefix = ""
	String pList = NMPulseWavePrefixList()
	
	Prompt wavePrefix, "enter new pulse wave prefix:"
	DoPrompt "Pulse Wave Prefix", wavePrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	if ( WhichListItem( wavePrefix, pList ) >= 0 )
		return "" // already exists
	endif

	NMPulseSet( wavePrefix = wavePrefix, history = 1 )
	
	return wavePrefix

End // z_NMPulseWavePrefixNewCall

//****************************************************************
//****************************************************************

Static Function /S z_NMPulseWavePrefixKillCall()
	
	String wavePrefix = CurrentNMPulseWavePrefix()
	String pList = NMPulseWavePrefixList()
	
	Prompt wavePrefix, "select wave prefix to kill:", popup pList
	DoPrompt "Pulse Wave Prefix", wavePrefix
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	return NMPulseWavePrefixKill( wavePrefix = wavePrefix, history = 1 )
	
End // z_NMPulseWavePrefixKillCall

//****************************************************************
//****************************************************************

Function /S NMPulseWavePrefixKill( [ wavePrefix, update, history ] )
	String wavePrefix
	Variable update
	Variable history
	
	String subfolder, pList, vlist = ""
	String thisfxn = GetRTStackInfo( 1 )
	
	String df = NMPulseDF()
	
	if ( ParamIsDefault( wavePrefix ) )
		wavePrefix = CurrentNMPulseWavePrefix()
	else
		vlist = NMCmdStrOptional( "wavePrefix", wavePrefix, vlist )
	endif
	
	subfolder = df + "Pulse_" + wavePrefix  + ":"
	
	if ( !DataFolderExists( subfolder ) )
		return "" // NM2ErrorStr( 30, "subfolder", subfolder )
	endif
	
	if ( StringMatch( subfolder, GetDataFolder( 1 ) ) == 1 )
		NMDoAlert( thisfxn + " Abort: cannot close the current data folder." )
		return "" // not allowed
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	Variable error = NMSubfolderKill( subfolder )
	
	if ( error == 0 )
	
		pList = NMPulseWavePrefixList()
		
		if ( ItemsInList( pList ) == 0 )
			SetNMstr( df + "CurrentPrefixPulse", WavePrefixDefault )
		else
			SetNMstr( df + "CurrentPrefixPulse", StringFromList( 0, pList ) )
		endif
		
	else
	
		subfolder = ""
		
	endif
	
	if ( update )
		NMPulseUpdate()
	endif
	
	return subfolder

End // NMPulseWavePrefixKill

//****************************************************************
//****************************************************************

Function /S CurrentNMPulseWavePrefix()

	String df = NMPulseDF()

	String wavePrefix = StrVarOrDefault( df + "CurrentPrefixPulse", "" )
	String subfolder = df + "Pulse_" + wavePrefix  + ":"
	
	if ( DataFolderExists( subfolder ) )
		return wavePrefix
	else
		return ""
	endif

End // CurrentNMPulseWavePrefix

//****************************************************************
//****************************************************************

Function /S NMPulseWavePrefixList( [ df ] )
	String df

	if ( ParamIsDefault( df ) || ( strlen( df ) == 0 ) )
		df = NMPulseDF()
	elseif ( !DataFolderExists( df ) )
		return NM2ErrorStr( 30, "df", df )
	endif

	String fList =  NMPulseSubfolderList( df = df )
	
	String prefixList = ReplaceString( "Pulse_", fList, "" )
	
	if ( ItemsInList( prefixList ) == 0 )
		prefixList = "Pulse;"
	endif
	
	return prefixList

End // NMPulseWavePrefixList

//****************************************************************
//****************************************************************

Function PulseTab( enable ) // called my ChangeTab
	Variable enable // ( 0 ) disable ( 1 ) enable tab
	
	if ( enable == 1 )
		CheckNMPackage( "Pulse", 1 ) // declare globals if necessary
		NMPulseMake() // create tab controls if necessary
		NMChannelGraphDisable( channel = -2, all = 0 )
	endif

End // PulseTab

//****************************************************************
//****************************************************************

Function PulseTabKill( what ) // called my KillTab
	String what
	
	String df = NMPulseDF
	
	strswitch( what )
	
		case "waves":
			// kill any other waves here
			break
			
		case "folder":
			if ( DataFolderExists( df ) == 1 )
				KillDataFolder $df
			endif
			break
			
	endswitch

End // PulseTabKill

//****************************************************************
//****************************************************************

Function NMPulseCheck() // declare global variables

	String df = NMPulseDF
	String sf = NMPulseSubfolder()
	
	if ( DataFolderExists( sf ) == 0 )
		NewDataFolder $RemoveEnding( sf, ":" )
	endif
	
	CheckNMvar( sf + "NumWaves", NumWavesDefault )
	CheckNMvar( sf + "DeltaX", DeltaxDefault )
	CheckNMvar( sf + "WaveLength", WaveLengthDefault )
	CheckNMstr( sf + "Xunits", NMXunits )
	CheckNMstr( sf + "Yunits", "" )
	CheckNMvar( sf + "PulseConfigNum", -1 )
	
	CheckNMvar( df + "AutoExecute", 0 )
	CheckNMvar( df + "OverwriteMode", 1 )
	//CheckNMvar( df + "EditByPrompt", 1 ) // NOT USED
	CheckNMvar( df + "PromptBinomial", 1 )
	CheckNMstr( df + "PromptTypeDSCG", "stdv" )
	CheckNMvar( df + "PromptPlasticity", 1 )
	CheckNMvar( df + "WaveNotes", 1 )
	CheckNMvar( df + "SaveStochasticValues", 1 )
	CheckNMvar( df + "SavePlasticityWaves", 1 )
	CheckNMvar( df + "TTL", 0 )
	
	NMPulseListBoxCheck()
	NMPulseListBox2Check()
	
	return 0
	
End // NMPulseCheck

//****************************************************************
//****************************************************************

Function NMPulseVar( varName )
	String varName
	
	String df = NMPulseDF
	String sf = NMPulseSubfolder()
	
	strswitch( varName )
	
		case "ConfigNum":
		case "PulseConfigNum":
			return NumVarOrDefault( sf + varName, -1 )
	
		case "NumWaves":
			return NumVarOrDefault( sf + varName, NumWavesDefault )
			
		case "DeltaX":
			return NumVarOrDefault( sf + varName, DeltaxDefault )
			
		case "WaveLength":
			return NumVarOrDefault( sf + varName, WaveLengthDefault )
			
		case "AutoExecute":
			return NumVarOrDefault( df + varName, 1 )
			
		case "OverwriteMode":
			return NumVarOrDefault( df + varName, 1 )
			
		//case "EditByPrompt":
			//return NumVarOrDefault( df + varName, 1 )
			
		case "PromptBinomial":
			return NumVarOrDefault( df + varName, 1 )
			
		case "PromptPlasticity":
			return NumVarOrDefault( df + varName, 1 )
			
		case "WaveNotes":
			return NumVarOrDefault( df + varName, 1 )
			
		case "SaveStochasticValues":
			return NumVarOrDefault( df + varName, 1 )
			
		case "SavePlasticityWaves":
			return NumVarOrDefault( df + varName, 1 )
			
		case "TTL":
			return NumVarOrDefault( df + varName, 0 )
	
	endswitch
	
	return NaN
	
End // NMPulseVar

//****************************************************************
//****************************************************************

Function /S NMPulseStr( varName )
	String varName
	
	String df = NMPulseDF()
	String sf = NMPulseSubfolder()
	
	strswitch( varName )
	
		case "WavePrefix":
			//return StrVarOrDefault( xsf + varName, WavePrefixDefault )
			return StrVarOrDefault( df + "CurrentPrefixPulse", WavePrefixDefault )
			
			
		case "Xunits":
			return StrVarOrDefault( sf + varName, NMXunits )
			
		case "Yunits":
			return StrVarOrDefault( sf + varName, "" )
			
		case "PromptTypeDSCG":
			return StrVarOrDefault( NMPulseDF + varName, "stdv" )
	
	endswitch
	
	return ""
	
End // NMPulseStr

//****************************************************************
//****************************************************************

Function NMPulseConfigs()

	NMConfigVar( "Pulse", "AutoExecute", 1, "auto compute waves after adding/editing pulses", "boolean" )
	NMConfigVar( "Pulse", "OverwriteMode", 1, "overwrite existing waves, tables and graphs if their is a name conflict", "boolean" )
	//NMConfigVar( "Pulse", "EditByPrompt", 1, "edit pulse listbox configs via user prompts", "boolean" )
	NMConfigVar( "Pulse", "PromptBinomial", 1, "prompt for binomial pulses", "boolean" )
	NMConfigVar( "Pulse", "PromptPlasticity", 1, "prompt for plasticity of pulse trains", "boolean" )
	NMConfigStr( "Pulse", "PromptTypeDSCG", "stdv", "prompt for \"delta\" or \"stdv\" or \"cv\" or \"gamma\" of pulse parameters", "delta;stdv;cv;gamma;" )
	NMConfigVar( "Pulse", "WaveNotes", 1, "save pulse parameters to wave notes", "boolean" )
	NMConfigVar( "Pulse", "SaveStochasticValues", 1, "save parameters that vary to output waves", "boolean" )
	NMConfigVar( "Pulse", "SavePlasticityWaves", 1, "save plasticity states variables (e.g. D and F) to waves", "boolean" )
	NMConfigVar( "Pulse", "TTL", 0, "sum waves using TTL logic", "boolean" )
	
End // NMPulseConfigs

//****************************************************************
//****************************************************************
//
//	Listbox Functions
//
//****************************************************************
//****************************************************************

Function NMPulseListBoxCheck( [ df, lbwName, nrows ] )
	String df
	String lbwName // e.g. "Configs"
	Variable nrows
	
	String eName
	
	if ( ParamIsDefault( df ) )
		df = NMPulseSubfolder()
	endif
	
	if ( ParamIsDefault( lbwName ) )
		lbwName = "Configs"
	endif
	
	if ( ParamIsDefault( nrows ) )
		nrows = 5
	endif
	
	eName = lbwName + "Editable"

	if ( !WaveExists( $df + lbwName ) )
		Make /T/N=( nrows, 2 ) $( df + lbwName ) = ""
	endif
	
	if ( !WaveExists( $df + eName ) )
		Make /N=( nrows, 2 ) $( df + eName ) = 0
	endif

End // NMPulseListBoxCheck

//****************************************************************
//****************************************************************

Function NMPulseListBoxUpdate( [ df, lbwName, extraRows, pcwName ] )
	String df
	String lbwName // e.g. "Configs"
	Variable extraRows
	String pcwName // see NMPulseConfigWaveName()
	
	Variable icnt, numConfigs, nrows, configNum
	String eName
	
	if ( ParamIsDefault( df ) )
		df = NMPulseSubfolder()
	endif
	
	if ( ParamIsDefault( lbwName ) )
		lbwName = "Configs"
	endif
	
	if ( ParamIsDefault( extraRows ) )
		extraRows = 5
	endif
	
	if ( ParamIsDefault( pcwName ) )
		pcwName = NMPulseConfigWaveName()
	endif
	
	NMPulseListBoxCheck( df = df, lbwName = lbwName, nrows = extraRows )
	
	eName = lbwName + "Editable"
	
	Wave /T configs = $df + lbwName
	Wave editable = $df + eName
	
	if ( ( WaveExists( $pcwName ) ) && ( WaveType( $pcwName, 1 ) == 2 ) )
	
		Wave /T pulses = $pcwName
		
		for ( icnt = 0 ; icnt < numpnts( pulses ) ; icnt += 1 )
			if ( strlen( pulses[ icnt ] ) > 0 )
				numConfigs += 1
			endif
		endfor
		
		nrows = numConfigs + extraRows
		
		Redimension /N=( nrows, 2 ) configs, editable
		
		configs[][ 0 ] = "+"
		configs[][ 1 ] = ""
		
		for ( icnt = 0 ; icnt < numpnts( pulses ) ; icnt += 1 )
		
			if ( ItemsInList( pulses[ icnt ] ) > 0 )
				configs[ icnt ][ 0 ] = "-"
				configs[ icnt ][ 1 ] = pulses[ icnt ]
			endif
			
		endfor
		
		configNum = NumVarOrDefault( df + "PulseConfigNum", 0 )
		
		if ( ( configNum <= 0 ) || ( configNum >= numpnts( $pcwName ) ) )
			SetNMvar( df + "PulseConfigNum", 0 )
		endif
		
	else
	
		configs[ ][ 0 ] = "+"
		configs[ ][ 1 ] = ""
		
		SetNMvar( df + "PulseConfigNum", 0 )
		
	endif
	
	editable = 0

End // NMPulseListBoxUpdate

//****************************************************************
//****************************************************************

Function NMPulseListbox( ctrlName, row, col, event ) : ListboxControl
	String ctrlName // name of this control
	Variable row // row if click in interior, -1 if click in title
	Variable col // column number
	Variable event // event code
	
	return NMPulseListboxEvent( row, col, event )
	
End // NMPulseListbox

//****************************************************************
//****************************************************************

Function NMPulseListboxEvent( row, col, event [ df, lbwName, pcwName ] )
	Variable row // row if click in interior, -1 if click in title
	Variable col // column number
	Variable event // event code
	String df // data folder
	String lbwName // e.g. "Configs"
	String pcwName // see NMPulseConfigWaveName()
	
	Variable value
	String wName, varName, valueStr
	
	if ( ParamIsDefault( df ) )
		df = NMPulseSubfolder()
	endif
	
	if ( ParamIsDefault( lbwName ) )
		lbwName = "Configs"
	endif
	
	if ( ParamIsDefault( pcwName ) )
		pcwName = NMPulseConfigWaveName()
	endif
	
	if ( WaveExists( $df + lbwName ) == 0 )
		return -1
	endif
	
	Wave /T configs = $df + lbwName
	
	if ( ( numtype( row ) > 0 ) || ( row < 0 ) || ( row >= DimSize( configs, 0 ) ) )
		return -1
	endif
	
	if ( ( numtype( col ) > 0 ) || ( col < 0 ) || ( col >= DimSize( configs, 1 ) ) )
		return -1
	endif
	
	varName = configs[ row ][ 0 ]
	valueStr = configs[ row ][ 1 ]
	value = str2num( valueStr )
	
	if ( StringMatch( varName, "+" ) )
		
		if ( event == 2 )
			NMPulsePromptCall()
		endif

	elseif ( StringMatch( varName, "-" ) && ( event == 2 ) )
	
		SetNMvar( df + "PulseConfigNum", row )
	
		if ( col == 0 )
			NMPulsePromptCall( row = row, OOD = 1 )
		endif
		
		NMPulseListBox2Update( df = df, lbwName = lbwName, pcwName = pcwName )

	endif
	
	return 0
	
End // NMPulseListboxEvent

//****************************************************************
//****************************************************************

Function NMPulseListBox2Check( [ df, lbwName, nrows ] )
	String df
	String lbwName // e.g. "Params"
	Variable nrows

	String eName
	
	if ( ParamIsDefault( df ) )
		df = NMPulseSubfolder()
	endif
	
	if ( ParamIsDefault( lbwName ) )
		lbwName = "Params"
	endif
	
	if ( ParamIsDefault( nrows ) )
		nrows = 5
	endif
	
	eName = lbwName + "Editable"
	
	if ( !WaveExists( $df + lbwName ) )
		Make /T/N=( nrows, 3 ) $( df + lbwName ) = ""
		Make /N=( nrows, 3 ) $( df + eName ) = 0
	endif
	
	if ( DimSize( $df + eName, 1 ) != 3 )
		Redimension /N=( -1, 3 ) $( df + lbwName )
		Redimension /N=( -1, 3 ) $( df + eName )
	endif

End // NMPulseListBox2Check

//****************************************************************
//****************************************************************

Function NMPulseListBox2Update( [ df, lbwName, pcwName, configNum ] )
	String df
	String lbwName // e.g. "Params"
	String pcwName // see NMPulseConfigWaveName()
	Variable configNum

	Variable nrows, icnt, ipnt, jcnt, kcnt
	Variable numParams, slen, canedit, items
	String paramList, paramList2, paramName, pstr
	String eName
	
	if ( ParamIsDefault( df ) )
		df = NMPulseSubfolder()
	endif
	
	if ( ParamIsDefault( lbwName ) )
		lbwName = "Params"
	endif
	
	if ( ParamIsDefault( pcwName ) )
		pcwName = NMPulseConfigWaveName()
	endif
	
	if ( ParamIsDefault( configNum ) )
		configNum = NumVarOrDefault( df + "PulseConfigNum", 0 )
	endif
	
	eName = lbwName + "Editable"
	
	NMPulseListBox2Check( df = df, lbwName = lbwName )
	
	Wave /T params = $df + lbwName
	Wave editable = $df + eName
	
	params = ""
	editable = 0
	
	nrows = DimSize( params, 0 )
	
	if ( WaveExists( $pcwName ) && ( configNum >= 0 ) && ( configNum < numpnts( $pcwName ) ) )
	
		Wave /T configs = $pcwName
		
		paramList = configs[ configNum ]
		
		if ( strlen( paramList ) == 0 )
			return 0
		endif
		
		numParams = ItemsInList( paramList )
		
		if ( nrows < numParams )
			Redimension /N=( numParams + 1, 3 ) params, editable
			nrows = numParams
		endif
		
		params[ 0 ][ 0 ] = "config"
		params[ 0 ][ 1 ] = num2istr( configNum )
		
		ipnt = 1
		
		for ( icnt = 0 ; icnt < numParams ; icnt += 1 )
		
			paramList2 = StringFromList( icnt, paramList )
			
			jcnt = strsearch( paramList2, "=", 0 )
			
			paramName = paramList2[ 0, jcnt - 1 ]
			
			params[ ipnt ][ 0 ] = paramName
			
			canedit = 3
			
			if ( StringMatch( paramName, "train" ) )
				//canedit = 0
			endif
			
			if ( StringMatch( paramName, "pulse" ) )
				canedit = 0
			endif
			
			if ( StringMatch( paramName, "off" ) )
				canedit = 0
			endif
			
			slen = strlen( paramList2 )
			
			paramList2 = paramList2[ jcnt + 1, slen - 1 ]
			
			paramList2 = ReplaceString( ",delta,", paramList2, ",delta=" )
			paramList2 = ReplaceString( ",stdv,", paramList2, ",stdv=" )
			paramList2 = ReplaceString( ",cv,", paramList2, ",cv=" )
			paramList2 = ReplaceString( ",gammaA,", paramList2, ",gammaA=" )
			paramList2 = ReplaceString( ",gammaB,", paramList2, ",gammaB=" )
			
			items = ItemsInList( paramList2, "," )
			
			pstr = StringFromList( 0, paramList2, "," )
			
			if ( strlen( pstr ) > 0 )
				params[ ipnt ][ 1 ] = pstr
				editable[ ipnt ][ 1 ] = canedit
			endif
			
			pstr = ""
			
			for ( kcnt = 1 ; kcnt < items ; kcnt += 1 )
				
				pstr += StringFromList( kcnt, paramList2, "," )
				
				if ( kcnt < items - 1 )
					pstr += ","
				endif
			
			endfor
			
			if ( StringMatch( paramName, "pulse" ) )
				params[ ipnt ][ 2 ] = ""
			elseif ( strlen( pstr ) > 0 )
				params[ ipnt ][ 2 ] = pstr
			else
				params[ ipnt ][ 2 ] = "+"
			endif
			
			editable[ ipnt ][ 2 ] = 0
			
			ipnt += 1
		
		endfor
	
	endif

End // NMPulseListBox2Update

//****************************************************************
//****************************************************************

Function NMPulseListBox2save( [ df, lbwName, pcwName, configNum, update ] )
	String df // data folder
	String lbwName // e.g. "Params"
	String pcwName // see NMPulseConfigWaveName()
	Variable configNum
	Variable update

	Variable icnt, nrows, ncols
	String pstr, paramList = ""
	
	if ( ParamIsDefault( df ) )
		df = NMPulseSubfolder()
	endif
	
	if ( ParamIsDefault( lbwName ) )
		lbwName = "Params"
	endif
	
	if ( ParamIsDefault( pcwName ) )
		pcwName = NMPulseConfigWaveName()
	endif
	
	if ( ParamIsDefault( configNum ) )
		configNum = NumVarOrDefault( df + "PulseConfigNum", 0 )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( !WaveExists( $df + lbwName ) || !WaveExists( $pcwName ) )
		return 0
	endif
	
	if ( ( configNum < 0 ) || ( configNum >= numpnts( $pcwName ) ) )
		return 0
	endif
	
	Wave /T params = $df + lbwName
	Wave /T configs = $pcwName
	
	nrows = DimSize( params, 0 )
	ncols = DimSize( params, 1 )
	
	if ( ncols != 3 )
		return 0
	endif

	for ( icnt = 1 ; icnt < nrows ; icnt += 1 )
	
		if ( strlen( params[ icnt ][ 0 ] ) == 0 )
			continue
		endif
	
		pstr = params[ icnt ][ 0 ] + "=" + params[ icnt ][ 1 ]
		
		if ( strlen( params[ icnt ][ 2 ] ) > 1 )
			pstr += "," + params[ icnt ][ 2 ]
		endif
		
		paramList += pstr + ";"
	
	endfor
	
	configs[ configNum ] = paramList
	
	if ( update )
		NMPulseUpdate()
	endif

End // NMPulseListBox2save

//****************************************************************
//****************************************************************

Function NMPulseListbox2( ctrlName, row, col, event ) : ListboxControl
	String ctrlName // name of this control
	Variable row // row if click in interior, -1 if click in title
	Variable col // column number
	Variable event // event code
	
	Variable TTL = NMPulseVar( "TTL" )
	
	return NMPulseListbox2Event( row, col, event, TTL = TTL )
	
End // NMPulseListbox2

//****************************************************************
//****************************************************************

Function NMPulseListbox2Event( row, col, event [ df, lbwName, pcwName, configNum, TTL ] )
	Variable row // row if click in interior, -1 if click in title
	Variable col // column number
	Variable event // event code
	String df // data folder
	String lbwName // e.g. "Configs"
	String pcwName // see NMPulseConfigWaveName()
	Variable configNum
	Variable TTL
	
	Variable value, dscgValue, dscgValue2, icnt, numRows, fixPolarity, fix2positive
	Variable Fratio, KF, F1, deltaF
	String varName, valueStr, dscg, dscgList, paramList, pstr
	
	if ( ParamIsDefault( df ) )
		df = NMPulseSubfolder()
	endif
	
	if ( ParamIsDefault( lbwName ) )
		lbwName = "Params"
	endif
	
	if ( ParamIsDefault( pcwName ) )
		pcwName = NMPulseConfigWaveName()
	endif
	
	if ( ParamIsDefault( configNum ) )
		configNum = NumVarOrDefault( df + "PulseConfigNum", 0 )
	endif
	
	if ( WaveExists( $df + lbwName ) == 0 )
		return -1
	endif
	
	Wave /T params = $df + lbwName
	
	if ( ( numtype( row ) > 0 ) || ( row < 0 ) || ( row >= DimSize( params, 0 ) ) )
		return -1
	endif
	
	if ( ( numtype( col ) > 0 ) || ( col < 0 ) || ( col >= DimSize( params, 1 ) ) )
		return -1
	endif
	
	varName = params[ row ][ 0 ]
	valueStr = params[ row ][ 1 ]
	value = str2num( valueStr )
	
	strswitch( varName )
		case "width":
		case "stdv":
		case "tau":
		case "tau1":
		case "tau2":
		case "tau3":
		case "tauRise":
		case "tauDecay":
		case "power":
		case "period":
			fix2positive = 1
			break
	endswitch
	
	if ( ( event == 2 ) && ( row > 0 ) && ( col == 2 ) && ( configNum >= 0 ) && ( configNum < numpnts( $pcwName ) ) )
	
		if ( StringMatch( varName, "config" ) || StringMatch( varName, "off" ) || StringMatch( varName, "pulse" ) )
			return 0
		endif
		
		if ( StringMatch( varName, "train" ) || StringMatch( varName, "tbgn" ) || StringMatch( varName, "tend" ) )
			return 0
		endif
		
		if ( StringMatch( varName, "interval" ) || StringMatch( varName, "refrac" ) )
			return 0
		endif
		
		if ( TTL && StringMatch( varName, "amp" ) )
			return 0
		endif
		
		paramList = params[ row ][ 2 ]
		
		strswitch( paramList[ 0, 1 ] )
			case "de":
				dscg = "delta"
				dscgValue = NumberByKey( "delta", paramList, "=", "," )
				break
			case "st":
				dscg = "stdv"
				dscgValue = NumberByKey( "stdv", paramList, "=", "," )
				break
			case "cv":
				dscg = "cv"
				dscgValue = NumberByKey( "cv", paramList, "=", "," )
				break
			case "ga":
				dscg = "gamma"
				dscgValue = NumberByKey( "gammaA", paramList, "=", "," )
				dscgValue2 = NumberByKey( "gammaB", paramList, "=", "," )
				break
			default:
				dscg = "none"
				dscgValue = 1
		endswitch
		
		if ( StringMatch( varName, "wave" ) )
			dscgList = "none;delta;"
		else
			dscgList = "none;delta;stdv;cv;gamma;"
		endif
		
		if ( strsearch( paramList, "FP", 0 ) > 0 )
			fixPolarity = 2
		else
			fixPolarity = 1
		endif
	
		Prompt dscg, "increment type:", popup dscgList
		Prompt fixPolarity, "fix polarity of " + varName + " parameter?", popup "no;yes;"
		
		DoPrompt "Edit Pulse Config #" + num2istr( configNum ), dscg
		
		if ( V_flag == 0 )
		
			strswitch( dscg )
			
				case "none":
					params[ row ][ 2 ] = ""
					break
					
				case "delta":
				case "stdv":
				case "cv":
				
					Prompt dscgValue, dscg + " value"
				
					if ( fix2positive )
						DoPrompt "Edit Pulse Config #" + num2istr( configNum ), dscgValue
						fixPolarity = 2
					else
						DoPrompt "Edit Pulse Config #" + num2istr( configNum ), dscgValue, fixPolarity
					endif
					
					if ( V_flag == 0 )
					
						pstr = dscg + "=" + num2str( dscgValue )
						
						if ( fixPolarity == 2 )
							pstr += ",FP"
						endif
						
						params[ row ][ 2 ] = pstr
						
					endif
					
					break
					
				case "gamma":
				
					Prompt dscgValue, "gamma A"
					
					pstr = ""
					
					if ( fix2positive )
						DoPrompt "Edit Pulse Config #" + num2istr( configNum ), dscgValue
					else
						DoPrompt "Edit Pulse Config #" + num2istr( configNum ), dscgValue
					endif
					
					if ( V_flag == 0 )
					
						pstr = "gammaA=" + num2str( dscgValue )
						
						if ( dscgValue2 == 0 )
							dscgValue2 = 1
						endif
						
						Prompt dscgValue2, "gamma B"
						
						if ( fix2positive )
							DoPrompt "Edit Pulse Config #" + num2istr( configNum ), dscgValue2
							fixPolarity = 2
						else
							DoPrompt "Edit Pulse Config #" + num2istr( configNum ), dscgValue2, fixPolarity
						endif
						
						if ( V_flag == 0 )
						
							pstr += ",gammaB=" + num2str( dscgValue2 )
							
							if ( fixPolarity == 2 )
								pstr += ",FP"
							endif
						
							params[ row ][ 2 ] = pstr
							
						else
						
							pstr = ""
							
						endif
						
					endif
					
					if ( strlen( pstr ) > 0 )
						params[ row ][ 2 ] = pstr
					endif
					
					break
					
			endswitch
			
			NMPulseListBox2save( df = df, lbwName = lbwName, pcwName = pcwName )
			
		endif
		
	elseif ( StringMatch( varName, "Fratio" ) && ( event == 7 ) )
	
		numRows = DimSize( params, 0 )
		
		Fratio = value
		F1 = NaN
		deltaF = NaN
		
		for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
			
			if ( StringMatch( params[ icnt ][ 0 ], "F1" ) )
				F1 = str2num( params[ icnt ][ 1 ] )
			endif
			
			if ( StringMatch( params[ icnt ][ 0 ], "deltaF" ) )
				deltaF = str2num( params[ icnt ][ 1 ] )
			endif
			
		endfor
		
		KF = NMPulseTrainDittmanKF( F1, Fratio, deltaF )
		
		for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
			if ( StringMatch( params[ icnt ][ 0 ], "KF" ) )
				params[ icnt ][ 1 ] = num2str( KF )
			endif
		endfor
		
	elseif ( StringMatch( varName, "KF" ) && ( event == 7 ) )
	
		numRows = DimSize( params, 0 )
		
		for ( icnt = 0 ; icnt < numRows ; icnt += 1 )
			if ( StringMatch( params[ icnt ][ 0 ], "Fratio" ) )
				params[ icnt ][ 1 ] = num2str( NaN )
			endif
		endfor
		
	elseif ( ( event == 7 ) && fix2positive )
	
		params[ row ][ 1 ] = num2str( abs( value ) )
		
	endif
	
	if ( event == 7 )
		NMPulseListBox2save( df = df, lbwName = lbwName, pcwName = pcwName )
	endif
	
End // NMPulseListbox2Event

//****************************************************************
//****************************************************************

Function NMPulseMake()

	Variable x0 = 20, xinc = 140, yinc = 25, fs = NMPanelFsize
	Variable y0 = NMPanelTabY + 35
	
	NMPulseCheck()
	
	String df = NMPulseDF
	String sf = NMPulseSubfolder()

	ControlInfo /W=$NMPanelName $"PU_configs"
	
	if ( V_Flag != 0 )
		NMPulseUpdate( stopAutoExecute = 1 )
		return 0 // tab controls exist, return here
	endif

	DoWindow /F $NMPanelName
	
	SetVariable PU_NumWaves, title="waves", pos={x0+xinc,y0}, limits={1,inf,0}, size={120,20}, win=$NMPanelName
	SetVariable PU_NumWaves, value=$( sf+"NumWaves" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	SetVariable PU_DeltaX, title="x-delta", pos={x0+xinc,y0+1*yinc}, limits={0,inf,0}, size={120,20}, win=$NMPanelName
	SetVariable PU_DeltaX, value=$( sf+"DeltaX" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	SetVariable PU_WaveLength, title="wave length", pos={x0+xinc,y0+2*yinc}, limits={0,inf,0}, size={120,20}, win=$NMPanelName
	SetVariable PU_WaveLength, value=$( sf+"WaveLength" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	//SetVariable PU_WavePrefix, title="wave prefix", pos={x0+xinc,y0}, size={120,20}, win=$NMPanelName
	//SetVariable PU_WavePrefix, value=$( df+"WavePrefix" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	PopupMenu PU_PrefixMenu, title=" ", pos={x0,y0-3}, size={120,20}, bodyWidth=120, win=$NMPanelName
	PopupMenu PU_PrefixMenu, mode=1, value="Wave Prefix", fsize=fs, proc=NMPulsePopup, win=$NMPanelName
	
	SetVariable PU_Xunits, title="x-units", pos={x0,y0+1*yinc}, size={120,20}, win=$NMPanelName
	SetVariable PU_Xunits, value=$( sf+"Xunits" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	SetVariable PU_Yunits, title="y-units", pos={x0,y0+2*yinc}, size={120,20}, win=$NMPanelName
	SetVariable PU_Yunits, value=$( sf+"Yunits" ), fsize=fs, proc=NMPulseSetVariable, win=$NMPanelName
	
	y0 += 80
	
	ListBox PU_configs, title="Pulse Configs", pos={x0,y0}, size={260,100}, fsize=fs, listWave=$( sf + "Configs" ), selWave=$( sf + "ConfigsEditable" ), win=$NMPanelName
	ListBox PU_configs, mode=1, userColumnResize=1, proc=NMPulseListbox, widths={25,1500}, win=$NMPanelName
	
	y0 += 115
	
	ListBox PU_params, title="Pulse Configs", pos={x0,y0}, size={260,120}, fsize=fs, listWave=$( sf + "Params" ), selWave=$( sf + "ParamsEditable" ), win=$NMPanelName
	ListBox PU_params, mode=1, userColumnResize=1, selRow=-1, proc=NMPulseListbox2, widths={35,70,45}, win=$NMPanelName
	
	y0 += 140
	yinc = 30
	
	Button PU_Execute, pos={x0+10,y0}, title="Execute", size={70,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	Button PU_Graph, pos={x0+95,y0}, title="Graph", size={70,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	Button PU_Table, pos={x0+180,y0}, title="Table", size={70,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	Button PU_Clear, pos={x0+55,y0+yinc}, title="Clear", size={70,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	Button PU_Model, pos={x0+140,y0+yinc}, title="Model", size={70,20}, proc=NMPulseButton, fsize=fs, win=$NMPanelName
	
	y0 += 65
	
	CheckBox PU_AutoExecute, title="auto execute", pos={x0+120,y0}, size={200,50}, value=0, proc=NMPulseCheckBox, fsize=fs, win=$NMPanelName
	
	NMPulseUpdate( stopAutoExecute = 1 )
	
End // NMPulseMake

//****************************************************************
//****************************************************************

Function NMPulseUpdate( [ stopAutoExecute ] )
	Variable stopAutoExecute

	Variable configNum
	String sf, wName, wavePrefix
	
	Variable auto = NMPulseVar( "AutoExecute" )

	NMPulseCheck()
	
	sf = NMPulseSubfolder()
	wName = NMPulseConfigWaveName()
	
	configNum = NMPulseVar( "PulseConfigNum" )
	
	if ( !WaveExists( $wName ) || ( numpnts( $wName ) == 0 ) )
		configNum = -1
	endif
	
	PopupMenu PU_PrefixMenu, mode=1, value=NMPulseWavePrefixMenu(), popvalue=CurrentNMPulseWavePrefix(), win=$NMPanelName
	
	SetVariable PU_NumWaves, value=$( sf + "NumWaves" ), win=$NMPanelName
	SetVariable PU_DeltaX, value=$( sf + "DeltaX" ), win=$NMPanelName
	SetVariable PU_WaveLength, value=$( sf + "WaveLength" ), win=$NMPanelName
	SetVariable PU_Xunits, value=$( sf + "Xunits" ), win=$NMPanelName
	SetVariable PU_Yunits, value=$( sf + "Yunits" ), win=$NMPanelName
	
	CheckBox PU_AutoExecute, value=auto, win=$NMPanelName
	
	ListBox PU_configs, listWave=$( sf + "Configs" ), selWave=$( sf + "ConfigsEditable" ), selRow=( configNum ), win=$NMPanelName
	ListBox PU_params, listWave=$( sf + "Params" ), selWave=$( sf + "ParamsEditable" ), selRow=-1, win=$NMPanelName
	
	NMPulseListBoxUpdate()
	NMPulseListBox2Update()
	
	if ( !stopAutoExecute && auto )
		NMPulseExecute()
	endif

End // NMPulseUpdate

//****************************************************************
//****************************************************************

Function /S NMPulseWavePrefixMenu()

	return "Wave Prefix;---;" + NMPulseWavePrefixList() + "---;Other;Kill;"

End //  NMPulseWavePrefixMenu

//****************************************************************
//****************************************************************

Function NMPulseButton( ctrlName ) : ButtonControl
	String ctrlName
	
	String fxn = ReplaceString( NMTabPrefix_Pulse(), ctrlName, "" )
	
	NMPulseCall( fxn, "" )
	
End // NMPulseButton

//****************************************************************
//****************************************************************

Function NMPulseSetVariable( ctrlName, varNum, varStr, varName ) : SetVariableControl
	String ctrlName; Variable varNum; String varStr; String varName
	
	String fxn = ReplaceString( NMTabPrefix_Pulse(), ctrlName, "" )
	
	NMPulseCall( fxn, varStr )
	
End // NMPulseSetVariable

//****************************************************************
//****************************************************************

Function NMPulseCheckBox( ctrlName, checked ) : CheckBoxControl
	String ctrlName; Variable checked
	
	ctrlName = ReplaceString( "PU_", ctrlName, "" )
	
	NMPulseCall( ctrlName, num2istr( checked ) )
	
End // NMPulseCheckBox

//****************************************************************
//****************************************************************

Function NMPulsePopup(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName; Variable popNum; String popStr
	
	ctrlName = ReplaceString( "PU_", ctrlName, "" )
	
	if ( StringMatch( ctrlName, "PrefixMenu" ) )
	
		strswitch( popStr)
	
		case "---":
		case "Wave Prefix":
			break
			
		case "Other":
			z_NMPulseWavePrefixNewCall()
			break
			
		case "Kill":
			z_NMPulseWavePrefixKillCall()
			break
			
		default:
	
			NMPulseSet( wavePrefix = popStr, history = 1 )
	
		endswitch
	
	endif

End // NMPulsePopup

//****************************************************************
//****************************************************************

Function /S NMPulseCall( fxn, select )
	String fxn // function name
	String select // parameter string variable
	
	Variable snum = str2num( select ) // parameter variable number
	
	String df = NMPulseDF
	
	strswitch( fxn )
	
		case "AutoExecute":
			NMConfigVarSet( "Pulse", "AutoExecute", BinaryCheck( snum  ) )
			break
	
		case "Execute":
			return NMPulseExecute( history = 1 )
			
		case "Graph":
			return NMMainCall( "Graph", "" )
			
		case "Table":
			return NMPulseTableCall()
			
		case "Clear":
			NMPulseConfigRemoveCall()
			break
			
		case "Model":
			NMPulseModelsCall()
			break
		
		case "WavePrefix":
			NMPulseSet( wavePrefix = select, history = 1 )
			break
			
		case "NumWaves":
			NMPulseSet( numWaves = snum, history = 1 )
			break
			
		case "DeltaX":
			NMPulseSet( dx = snum, history = 1 )
			break
			
		case "WaveLength":
			NMPulseSet( waveLength = snum, history = 1 )
			break
			
		case "Xunits":
			NMPulseSet( xunits = select, history = 1 )
			break
			
		case "Yunits":
			NMPulseSet( yunits = select, history = 1 )
			break

	endswitch
	
	return ""
	
End // NMPulseCall

//****************************************************************
//****************************************************************

Function NMPulseSet( [ wavePrefix, numWaves, dx, waveLength, xunits, yunits, update, history ] )
	String wavePrefix
	Variable numWaves, dx, waveLength
	String xunits, yunits
	Variable update
	Variable history // print function command to history ( 0 ) no ( 1 ) yes
	
	String vlist = ""
	String df = NMPulseDF()
	String sf = NMPulseSubfolder()
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( !ParamIsDefault( wavePrefix ) && ( strlen( wavePrefix ) > 0 ) )
		vlist = NMCmdStrOptional( "wavePrefix", wavePrefix, vlist )
		SetNMstr( df + "CurrentPrefixPulse", wavePrefix )
	endif
	
	if ( !ParamIsDefault( xunits ) && ( strlen( xunits ) > 0 ) )
		vlist = NMCmdStrOptional( "xunits", xunits, vlist )
		SetNMstr( sf + "Xunits", xunits )
	endif
	
	if ( !ParamIsDefault( yunits ) && ( strlen( yunits ) > 0 ) )
		vlist = NMCmdStrOptional( "yunits", yunits, vlist )
		SetNMstr( sf + "Yunits", yunits )
	endif
	
	if ( !ParamIsDefault( numWaves ) && ( numWaves > 0 ) )
		vlist = NMCmdNumOptional( "numWaves", numWaves, vlist )
		SetNMvar( sf + "NumWaves", numWaves )
	endif
	
	if ( !ParamIsDefault( dx ) && ( dx > 0 ) )
		vlist = NMCmdNumOptional( "dx", dx, vlist )
		SetNMvar( sf + "DeltaX", dx )
	endif
	
	if ( !ParamIsDefault( waveLength ) && ( waveLength > 0 ) )
		vlist = NMCmdNumOptional( "waveLength", waveLength, vlist )
		SetNMvar( sf + "WaveLength", waveLength )
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( update )
		NMPulseUpdate()
	endif

End // NMPulseSet

//****************************************************************
//****************************************************************

Function /S NMPulsePromptCall( [ row, OOD ] )
	Variable row
	Variable OOD // on / off / delete
	
	Variable editExisting, select, off
	String pList, paramList = "", titleEnding = ""
	String wName = NMPulseConfigWaveName()
	
	Variable numWaves = NMPulseVar( "NumWaves" )
	Variable waveLength = NMPulseVar( "WaveLength" )
	String wavePrefix = NMPulseStr( "WavePrefix" )
	
	Variable binom = NMPulseVar( "PromptBinomial" )
	Variable plasticity = NMPulseVar( "PromptPlasticity" )
	Variable TTL = NMPulseVar( "TTL" )
	String DSCG = NMPulseStr( "PromptTypeDSCG" )
	
	if ( !ParamIsDefault( row ) && WaveExists( $wName ) )
	
		if ( row >= numpnts( $wName ) )
			return ""
		endif
		
		Wave /T wtemp = $wName
		
		paramList = wtemp[ row ]
		
		editExisting = 1
		
		if ( OOD )
			
			off = str2num( StringByKey( "off", paramList, "=" ) )
			
			if ( off )
				pList = "turn on;delete;"
				off = 0
			else
				pList = "turn off;delete;"
				off = 1
			endif
			
			select = 1
		
			Prompt select, " ", popup plist
			DoPrompt "Remove Pulse Config #" + num2istr( row ), select
			
			if ( V_flag == 1 )
				return "" // cancel
			endif
			
			if ( select == 1 ) // on / off
				
				NMPulseConfigRemove( configNum = row, off = off, history = 1 )
				
			elseif ( select == 2 ) // delete
			
				NMPulseConfigRemove( configNum = row, history = 1 )
				
			endif
			
			return ""
		
		endif
	
	endif
	
	paramList = NMPulsePrompt( pdf = NMPulseDF, numWaves = numWaves, timeLimit = waveLength, paramList = paramList, TTL = TTL, titleEnding = titleEnding, binom = binom, DSC = DSCG, plasticity = plasticity )

	if ( strlen( paramList ) == 0 )
		return "" // cancel
	endif
	
	if ( editExisting )
		wtemp[ row ] = paramList
	else
		NMPulseConfigAdd( paramList, history = 1 )
	endif
	
	NMPulseUpdate()
	
	return paramList

End // NMPulsePromptCall

//****************************************************************
//****************************************************************

Function /S NMPulseConfigWaveName()
	
	return NMPulseSubfolder() + "PulseParamLists"

End // NMPulseConfigWaveName

//****************************************************************
//****************************************************************

Function NMPulseConfigAdd( paramList [ pcwName, update, history ] )
	String paramList
	String pcwName
	Variable update
	Variable history
	
	Variable error
	String cmd
	
	String bullet = NMCmdHistoryBullet()
	
	Variable cmdhistory = NMVarGet( "CmdHistory" )
	
	if ( ParamIsDefault( pcwName ) )
		pcwName = NMPulseConfigWaveName()
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( cmdhistory && history )
	
		cmd = GetRTStackInfo( 1 ) + "( \"" + paramList + "\" )"
		
		NMHistoryManager( bullet + cmd, -1 * cmdhistory )
		
	endif
	
	error = NMPulseConfigWaveSave( pcwName, paramList )
	
	if ( update )
		NMPulseUpdate()
	endif
	
	return error
	
End // NMPulseConfigAdd

//****************************************************************
//****************************************************************

Function NMPulseConfigRemoveCall()

	Variable select = 1
	
	Prompt select, " ", popup "clear all pulse configs;turn off all pulse configs;"
	DoPrompt "NM Pulse Configs", select
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	if ( select == 1 )
		return NMPulseConfigRemove( all = 1, history = 1 )
	elseif ( select == 2 )
		return NMPulseConfigRemove( all = 1, off = 1, history = 1 )
	endif

End // NMPulseConfigRemoveCall

//****************************************************************
//****************************************************************

Function NMPulseConfigRemove( [ configNum, all, off, update, history ] )
	Variable configNum
	Variable all
	Variable off // ( 0 ) turn on config ( 1 ) turn off config
	Variable update
	Variable history
	
	Variable success, error
	String vlist = ""
	String wName = NMPulseConfigWaveName()
	
	if ( !WaveExists( $wName ) )
		return 0
	endif
	
	if ( ParamIsDefault( configNum ) )
		configNum = -1
	else
		vlist = NMCmdNumOptional( "configNum", configNum, vlist, integer = 1 )
	endif
	
	if ( !ParamIsDefault( all ) )
		vlist = NMCmdNumOptional( "all", all, vlist, integer = 1 )
	endif
	
	if ( ParamIsDefault( off ) )
		off = -1
	else
		vlist = NMCmdNumOptional( "off", off, vlist, integer = 1 )
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( vlist )
	endif
	
	if ( all )
		error = NMPulseConfigWaveRemove( wName, all = 1, off = off )
	else
		error = NMPulseConfigWaveRemove( wName, configNum = configNum, off = off )
	endif
	
	if ( update )
		NMPulseUpdate()
	endif
	
	return success
	
End // NMPulseConfigRemove

//****************************************************************
//****************************************************************

Function /S NMPulseTableCall()

	Variable type = NumVarOrDefault( NMPulseDF + "Prompt_TableType", 2 )
	
	Prompt type, "select table type:", popup "configs;stochastic parameters;"
	DoPrompt "NM Pulse Table", type
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( NMPulseDF + "Prompt_TableType", type )
	
	switch( type )
		case 1:
			return NMPulseConfigsTable( history = 1 )
		case 2:
			return NMPulseOutputTable( history = 1 )
	endswitch
		
	return ""

End // NMPulseTableCall

//****************************************************************
//****************************************************************

Function /S NMPulseConfigsTable( [ history ] )
	Variable history

	String wName = NMPulseConfigWaveName()
	String folderPrefix = NMFolderListName( "" )
	String wavePrefix = NMPulseStr( "WavePrefix" )
	String tName = NMTabPrefix_Pulse() + "Configs_" + folderPrefix + "_" + wavePrefix
	String title =  folderPrefix + " : " + wavePrefix + " : Pulse Configs"
	
	STRUCT Rect w
	
	NMOutputListsReset()
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	if ( !WaveExists( $wName ) )
		NMPulseConfigAdd( "" )
	endif
	
	if ( ( strlen( tName ) > 0 ) && ( WinType( tName ) == 0 ) )
	
		NMWinCascadeRect( w )
		
		Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) $wName as title
		
		Execute /Z "ModifyTable title( Point )= " + NMQuotes( "Config" )
		Execute /Z "ModifyTable alignment=0"
		Execute /Z "ModifyTable width=400"
		Execute /Z "ModifyTable width( Point )=40"
		
		SetWindow $tName hook=NMPulseConfigsTableHook, hookevents=1
		
	else
	
		DoWindow /F $tName
		
	endif
	
	SetNMstr( NMDF + "OutputWinList", tName )
	
	NMHistoryOutputWindows()
	
	return tName

End // NMPulseConfigsTable

//****************************************************************
//****************************************************************

Function NMPulseConfigsTableHook( infoStr )
	string infoStr
	
	string event = StringByKey( "EVENT", infoStr )
	string winNameStr = StringByKey( "WINDOW", infoStr )
	
	strswitch( event )
		case "activate":
		case "moved":
			break
		case "deactivate":
		case "kill":
			NMPulseUpdate( stopAutoExecute = 1 )
	endswitch
	
	return 0

End // NMPulseConfigsTableHook

//****************************************************************
//****************************************************************

Function /S NMPulseOutputTable( [ sf, wList, history ] )
	String sf // subfolder
	String wList // output wave name list or "all"
	Variable history
	
	Variable wcnt
	String wName, tName, title, vlist = "", tList = ""
	
	String folderPrefix = NMFolderListName( "" )
	String wavePrefix = NMPulseStr( "WavePrefix" )
	
	STRUCT Rect w
	
	NMOutputListsReset()

	if ( ParamIsDefault( sf ) )
		sf = NMPulseSubfolder()
	else
		vlist = NMCmdStrOptional( "sf", sf, vlist )
	endif
	
	if ( ParamIsDefault( wList ) )
		wList = "all"
	else
		vlist = NMCmdStrOptional( "wList", wList, vlist )
	endif
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	If ( !DataFolderExists( sf ) )
		return ""
	endif
	
	if ( StringMatch( wList, "all" ) )
		wList = NMFolderWaveList( sf, "PC*", ";", "", 0 )
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
		
		wName = StringFromList( wcnt, wList )
		
		if ( !WaveExists( $sf + wName ) )
			continue
		endif
		
		tName = NMTabPrefix_Pulse() + folderPrefix + "_" + wavePrefix + "_" + wName
		title =  folderPrefix + " : " + wavePrefix + " : " + wName
		
		if ( ( strlen( tName ) > 0 ) && ( WinType( tName ) == 0 ) )
	
			NMWinCascadeRect( w )
			
			Edit /K=1/N=$tName/W=(w.left,w.top,w.right,w.bottom) $( sf + wName ) as title
			
		else
		
			DoWindow /F $tName
			
		endif
		
		tList += tName + ";"
		
	endfor
	
	SetNMstr( NMDF + "OutputWinList", tList )
	
	NMHistoryOutputWindows()

	return tList

End // NMPulseOutputTable

//****************************************************************
//****************************************************************

Function /S NMPulseExecute( [ history ] )
	Variable history

	Variable wcnt, wavesExist, waveLength, dx
	String wName, wList
	
	String pulseWaveName = NMPulseConfigWaveName()
	String sf = NMPulseSubfolder()
	
	String currentPrefix = CurrentNMWavePrefix()
	Variable currentNumWaves = NMNumWaves()
	
	Variable overwrite = NMPulseVar( "OverwriteMode" )
	Variable wNotes = NMPulseVar( "WaveNotes" )
	Variable saveStochastic = NMPulseVar( "SaveStochasticValues" )
	Variable savePlasticity = NMPulseVar( "SavePlasticityWaves" )
	
	STRUCT NMParams nm
	STRUCT NMMakeStruct m
	STRUCT NMPulseSaveToWaves s
	
	NMParamsNull( nm )
	NMMakeStructNull( m )
	
	waveLength = NMPulseVar( "WaveLength" )
	dx = NMPulseVar( "DeltaX" )
	
	nm.folder = CurrentNMFolder( 1 )
	nm.wavePrefix = NMPulseStr( "WavePrefix" )
	
	m.numWaves = NMPulseVar( "NumWaves" )
	m.xpnts = 1 + waveLength / dx
	m.dx = dx
	m.xLabel = NMPulseStr( "Xunits" )
	m.yLabel = NMPulseStr( "Yunits" )
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	if ( ( numtype( m.numWaves ) > 0 ) || ( m.numWaves < 1 ) )
		return ""
	endif
	
	if ( ( numtype( m.dx ) > 0 ) || ( m.dx <= 0 ) )
		m.dx = 1
	endif
	
	if ( ( numtype( m.xpnts ) > 0 ) || ( m.xpnts <= 0 ) )
		return ""
	endif
	
	if ( strlen( nm.wavePrefix ) == 0 )
		nm.wavePrefix = WavePrefixDefault
	endif
	
	//m.rows = 1 + m.waveLength / m.dx
	
	nm.wList = ""
	
	for ( wcnt = 0 ; wcnt < m.numWaves ; wcnt += 1 )
	
		wName = nm.wavePrefix + num2istr( wcnt )
		
		if ( WaveExists( $nm.folder + wName ) )
			wavesExist = 1
		endif
		
		nm.wList += wName + ";"
		
	endfor
	
	if ( wavesExist && !overwrite )
	
		NMDoAlert( "Abort Pulse Execution: waves with prefix " + NMQuotes( nm.wavePrefix ) + " already exist", title = "Pulse Execute" )
	
		return ""
	
	endif
	
	wList = WaveList( nm.wavePrefix + "*", ";", "" )
	
	wList = RemoveFromList( nm.wList, wList )
	
	if ( ItemsInList( wList ) > 0 )
	
		DoAlert /T="NM Pulse Wave Generator" 1, "There are extra waves with prefix " + NMQuotes( nm.wavePrefix ) + " in the current data folder. Do you want to delete them?"
		
		if ( V_flag == 1 )
		
			for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
				wName = StringFromList( wcnt, wList )
				KillWaves /Z $wName
			endfor
			
		endif
	
	endif
	
	//Variable timerRefNum = startMSTimer
	
	if ( saveStochastic )
	
		s.sf = sf
	
		NMPulseWavesMake2( pulseWaveName, nm, m, notes = wNotes, savePlasticityWaves = savePlasticity, s = s )
	
	else
	
		NMPulseWavesMake2( pulseWaveName, nm, m, notes = wNotes, savePlasticityWaves = savePlasticity )
	
	endif
	
	NMPulseSave()
	
	//print round( stopMSTimer( timerRefNum ) / 1000 ), "ms"
	
	if ( StringMatch( currentPrefix, nm.wavePrefix ) && ( currentNumWaves == m.numWaves ) )
		UpdateCurrentWave()
	else
		NMPrefixSelect( nm.wavePrefix, noPrompts = 1 )
	endif
	
	NMLoopHistory( nm )
	
	return nm.wList

End // NMPulseExecute

//****************************************************************
//****************************************************************

Function NMPulseSave() // copy Pulse subfolder to current folder - this saves variables used in current simulation

	String wavePrefix, sf, sfnew
	String df = NMPulseDF()
	
	if ( StringMatch( df, NMPulseDF ) ) // using Package Pulse directory
		
		wavePrefix = StrVarOrDefault( NMPulseDF + "CurrentPrefixPulse", "" )
		
		if ( strlen( wavePrefix ) == 0 )
			return -1 // something is wrong
		endif
		
		sf = NMPulseDF + "Pulse_" + wavePrefix  + ":"
		
		if ( !DataFolderExists( sf ) )
			return -1 // something is wrong
		endif
		
		sfnew = CurrentNMFolder( 1 ) + "Pulse_" + wavePrefix  + ":"
		
		if ( DataFolderExists( sfnew ) )
			KillDataFolder /Z $RemoveEnding( sfnew, ":" )
		endif
		
		SetNMstr( CurrentNMFolder( 1 ) + "CurrentPrefixPulse", wavePrefix )
		
		DuplicateDataFolder $RemoveEnding( sf, ":" ) $RemoveEnding( sfnew, ":" )
	
	endif

End // NMPulseSave

//****************************************************************
//****************************************************************

Function NMPulseModelsCall()

	String df = NMPulseDF

	Variable model = NumVarOrDefault( df + "Prompt_GCModelSelect", 1 )

	String modelList = " ;Granule Cell Multinomial Synapse;Granule Cell Synaptic Conductance Train with Short-Term Plasticity;"
	
	Prompt model, "select model to run:", popup modelList
	DoPrompt "NM Pulse Models", model
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	SetNMvar( df + "Prompt_GCModelSelect", model )
	
	switch( model )
	
		case 2:
			return NMPulseGCBinomSynCall()
			
		case 3:
			NMPulseGCTrainCall()
			break
	
	endswitch

End // NMPulseModelsCall

//****************************************************************
//****************************************************************

Function NMPulseGCBinomSynCall()

	String df = NMPulseDF
	String sf = NMPulseSubfolder()
	
	String title = "NM Pulse GC Binomial Synapse"

	Variable numWaves = NumVarOrDefault( df + "NumWaves", 100 )
	numWaves = NumVarOrDefault( sf + "NumWaves", numWaves )
	
	Variable dx = NumVarOrDefault( df + "DeltaX", 0.005 )
	dx = NumVarOrDefault( sf + "DeltaX", dx )
	
	Variable waveLength = NumVarOrDefault( df + "WaveLength", 8 )
	waveLength = NumVarOrDefault( sf + "WaveLength", waveLength )
	
	if ( ( numWaves == NumWavesDefault ) && ( dx == DeltaxDefault ) && ( waveLength == WaveLengthDefault ) )
		numWaves = 100
		dx = 0.005
		waveLength = 8
	endif
	
	Variable Nsites = NumVarOrDefault( df + "Prompt_GCBinomN", 5 )
	Variable Pr = NumVarOrDefault( df + "Prompt_GCBinomP", 0.5 )
	Variable Q = NumVarOrDefault( df + "Prompt_GCBinomQ", -16 )
	
	Variable latencySTDV = NumVarOrDefault( df + "Prompt_GCBinomLatSTDV", 0.08 )
	Variable CVQS = NumVarOrDefault( df + "Prompt_GCBinomCVQS", 0.3 )
	Variable CVQ2 = NumVarOrDefault( df + "Prompt_GCBinomCVQ2", 0.3 )
	
	Variable FixCVQ2 = 1 + NumVarOrDefault( df + "Prompt_GCBinomFixCVQ2", 1 )
	Variable CVQ2precision = NumVarOrDefault( df + "Prompt_GCBinomCVQ2precision", 1 ) // %
	Variable CVQ2precisionAmp = NumVarOrDefault( df + "Prompt_GCBinomCVQ2precisionAmp", 1 ) // %
	Variable addSpillover = 1 + NumVarOrDefault( df + "Prompt_GCBinomAddSpillover", 0 )
	
	if ( numWaves <= 1 )
		numWaves = 100
	endif
	
	Prompt numWaves, "number of waves to compute:"
	Prompt dx, "wave sample interval (delta-x):"
	Prompt waveLength, "wave length:"
	
	Prompt Nsites, "release sites per synapse:"
	Prompt Pr, "release probability:"
	Prompt Q, "quantal peak response per site:"
	Prompt latencySTDV, "STDV of quantal latency:"
	Prompt CVQS, "within-site Q variability ( CVQS ):"
	Prompt CVQ2, "between-site Q variability ( CVQ2 ):"
	Prompt FixCVQ2, "fix simulated CVQ2 to a given precision?", popup "no;yes;"
	Prompt CVQ2precision, "% precision to fix CVQ2:"
	Prompt CVQ2precisionAmp, "% precision to fix mean Q:"
	Prompt addSpillover, "add spillover?", popup "no;yes;"
	
	DoPrompt title, numWaves, dx, waveLength
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	SetNMvar( sf + "NumWaves", numWaves )
	SetNMvar( sf + "DeltaX", dx )
	SetNMvar( sf + "WaveLength", waveLength )
	
	DoPrompt title, Nsites, Pr, Q, addSpillover
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	addSpillover -= 1
	
	SetNMvar( df + "Prompt_GCBinomN", Nsites )
	SetNMvar( df + "Prompt_GCBinomP", Pr )
	SetNMvar( df + "Prompt_GCBinomQ", Q )
	SetNMvar( df + "Prompt_GCBinomAddSpillover", addSpillover )
	
	DoPrompt title, latencySTDV, CVQS, CVQ2
	
	if ( V_flag == 1 )
		return 0 // cancel
	endif
	
	SetNMvar( df + "Prompt_GCBinomLatSTDV", latencySTDV )
	SetNMvar( df + "Prompt_GCBinomCVQS", CVQS )
	SetNMvar( df + "Prompt_GCBinomCVQ2", CVQ2 )
	
	if ( CVQ2 > 0 )
	
		DoPrompt title, FixCVQ2
		
		if ( V_flag == 1 )
			return 0 // cancel
		endif
		
		FixCVQ2 -= 1
		
		SetNMvar( df + "Prompt_GCBinomFixCVQ2", FixCVQ2 )
		
		if ( FixCVQ2 )
	
			DoPrompt title, CVQ2precision, CVQ2precisionAmp
		
			if ( V_flag == 1 )
				return 0 // cancel
			endif
			
			SetNMvar( df + "Prompt_GCBinomCVQ2precision", CVQ2precision )
			SetNMvar( df + "Prompt_GCBinomCVQ2precisionAmp", CVQ2precisionAmp )
		
		endif
	
	endif

	return NMPulseGCBinomSyn( numWaves=numWaves, dx=dx, waveLength=waveLength, Nsites=Nsites, Pr=Pr, Q=Q, latencySTDV=latencySTDV, CVQS=CVQS, CVQ2=CVQ2, FixCVQ2=FixCVQ2, CVQ2precision=CVQ2precision, CVQ2precisionAmp=CVQ2precisionAmp, addSpillover=addSpillover, history=1 )
	
End // NMPulseGCBinomSynCall

//****************************************************************
//****************************************************************

Function NMPulseGCBinomSyn( [ numWaves, dx, waveLength, Nsites, Pr, Q, latencySTDV, CVQS, CVQ2, FixCVQ2, CVQ2precision, CVQ2precisionAmp, addSpillover, update, history ] )
	Variable numWaves, dx, waveLength
	Variable Nsites, Pr, Q // binomial, number of release sites, probability of release, quantal size
	Variable latencySTDV // creates CVQL
	Variable CVQS, CVQ2
	Variable FixCVQ2, CVQ2precision, CVQ2precisionAmp
	Variable addSpillover
	Variable update
	Variable history

	Variable Qvalue, amp, site
	String sf, paramList, wName
	
	String wavePrefix = "EPSC"
	String df = NMPulseDF()
	
	if ( ParamIsDefault( numWaves ) )
		numWaves = 10
	endif
	
	if ( ParamIsDefault( dx ) )
		dx = 0.01
	endif
	
	if ( ParamIsDefault( waveLength ) )
		waveLength = 5
	endif
	
	if ( ParamIsDefault( Nsites ) )
		Nsites = 5
	endif
	
	if ( ParamIsDefault( Pr ) )
		Pr = 0.5
	endif
	
	if ( ParamIsDefault( Q ) )
		Q = -16
	endif
	
	if ( ParamIsDefault( latencySTDV ) )
		latencySTDV = 0 // 0.08
	endif
	
	if ( ParamIsDefault( CVQS ) )
		CVQS = 0 // 0.3
	endif
	
	if ( ParamIsDefault( CVQ2 ) )
		CVQ2 = 0 // 0.3
	endif
	
	if ( ParamIsDefault( FixCVQ2 ) )
		FixCVQ2 = 1
	endif
	
	if ( ParamIsDefault( CVQ2precision ) )
		CVQ2precision = 1 // %
	endif
	
	if ( ParamIsDefault( CVQ2precisionAmp ) )
		CVQ2precisionAmp = 1 // %
	endif
	
	//Variable APonset = 0.44 // 0.5
	
	Variable latencyFromAP = 0.5 // 1.0 // APonset + latencySTDV * 7
	
	Variable spilloverLatency = latencyFromAP + 0.18 // 0.18 + 7 * 0.08 = 0.74 // from AP
	Variable spilloverAmp = -3.471
	Variable spilloverAmpCV = 0.31
	
	Variable year = 2005 // 2002 // or 2012
	
	String directList = NMPulseSynExp4_GC_AMPAdirect( year=year )
	String spillList = NMPulseSynExp4_GC_AMPAspill( year=year )
	
	directList = RemoveFromList( "pulse=synexp4", directList, ";" )
	spillList = RemoveFromList( "pulse=synexp4", spillList, ";" )
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	NMPulseConfigRemove( all=1 )
	
	SetNMstr( df + "CurrentPrefixPulse", wavePrefix )
	
	NMPulseCheck()
	
	sf = NMPulseSubfolder()
	
	SetNMvar( sf + "NumWaves", numWaves )
	SetNMvar( sf + "WaveLength", waveLength )
	SetNMvar( sf + "DeltaX", dx )
	
	SetNMstr( sf + "Xunits", NMXunits )
	SetNMstr( sf + "Yunits", "pA" )
	
	NMPulseConfigRemove( all = 1 )
	
	if ( CVQ2 > 0 )
	
		wName = NMPulseGCBinomSynSiteAmps( Nsites, Q, CVQ2, CVQ2precision = CVQ2precision, CVQ2precisionAmp = CVQ2precisionAmp )
	
		if ( strlen( wName ) == 0 )
			return -1 // error
		endif
		
		Wave amps = $wName
	
		for ( site = 0 ; site < Nsites ; site += 1 )
		
			if ( site >= numpnts( amps ) )
				break
			endif
	
			//amp = Q + gnoise( Q * CVQ2 )
			//amps[ site ] = amp
			amp = amps[ site ]
		
			paramList = "wave=all;pulse=synexp4;"
			paramList += NMPulseParamList( "amp", amp, cv = CVQS, fixPolarity = 1 )
			paramList += NMPulseParamList( "onset", latencyFromAP, stdv = latencySTDV )
			//paramList += NMPulseParamList( "width", inf )
			paramList += directList
			paramList += NMPulseParamList( "binomialN", 1 )
			paramList += NMPulseParamList( "binomialP", Pr )
			
			NMPulseConfigAdd( paramList, history = 1 )
		
		endfor
	
	else
	
		paramList = "wave=all;pulse=synexp4;"
		paramList += NMPulseParamList( "amp", Q )
		paramList += NMPulseParamList( "onset", latencyFromAP, stdv = latencySTDV )
		//paramList += NMPulseParamList( "width", inf )
		paramList += directList
		paramList += NMPulseParamList( "binomialN", Nsites )
		paramList += NMPulseParamList( "binomialP", Pr )
		
		NMPulseConfigAdd( paramList, history = 1 )
	
	endif
	
	if ( addSpillover )
	
		paramList = "wave=all;pulse=synexp4;"
		paramList += NMPulseParamList( "amp", spilloverAmp, cv = spilloverAmpCV, fixPolarity = 1 )
		paramList += NMPulseParamList( "onset", spilloverLatency )
		//paramList += NMPulseParamList( "width", inf )
		paramList += spillList
		
		NMPulseConfigAdd( paramList, history = 1 )
		
	endif
	
	if ( update )
		NMPulseUpdate()
	endif
	
End // NMPulseGCBinomSyn

//****************************************************************
//****************************************************************

Function /S NMPulseGCBinomSynSiteAmps( binomialN, Q, CVQ2 [ CVQ2precision, CVQ2precisionAmp ] ) // set mean amplitude of individual sites ( added 19/01/04 )
	Variable binomialN, Q, CVQ2
	Variable CVQ2precision, CVQ2precisionAmp
	
	Variable icnt, cvlogic, avglogic, avgAmp, sqrtN, CVQ22, FixCVQ2, maxloops = 1e20
	String sf = NMPulseSubfolder()
	
	String wName = "MeanSiteAmp"
	
	Make /D/O/N=( binomialN ) $sf + wName = Q
	
	Wave amps = $sf + wName
	
	//sqrtN = sqrt( N / ( N - 1 ) ) // David's old code
	sqrtN = 1 // Federico's code, POPULATION VERSUS SAMPLE VARIANCE ????
	
	if ( !ParamIsDefault( CVQ2precision ) && ( CVQ2precision > 0 ) && ( CVQ2precision < 100 ) )
		if ( !ParamIsDefault( CVQ2precisionAmp ) && ( CVQ2precisionAmp > 0 ) && ( CVQ2precisionAmp < 100 ) )
			FixCVQ2 = 1
		endif
	endif
	
	CVQ2 = abs( CVQ2 )
	
	CVQ2precision /= 100 // convert to fraction
	CVQ2precisionAmp /= 100 // convert to fraction
	
	if ( ( binomialN > 1 ) && ( CVQ2 > 0 ) )
	
		if ( FixCVQ2 )
		
			do
	
				amps = Q + gnoise( Q * CVQ2 * sqrtN )
				
				WaveStats /Q amps
				
				CVQ22 = ( V_sdev * sqrtN / V_avg ) ^ 2
				avgAmp = abs( V_avg )
				
				cvlogic = ( CVQ22 > CVQ2 ^ 2 * ( 1 + CVQ2precision ) ) || ( CVQ22 < CVQ2 ^ 2 * ( 1 - CVQ2precision ) )
				avglogic = ( avgAmp > abs( Q * ( 1 + CVQ2precisionAmp ) ) ) || ( avgAmp < abs( Q * ( 1 - CVQ2precisionAmp ) ) )
				
				if ( icnt > maxloops )
					NMDoAlert( "Error: FixCVQ2 failed to converge. Try running again." )
					return ""
				endif
				
				icnt += 1
				
			while ( cvlogic || avglogic ) // loop while this expression is TRUE
			
			//Print icnt, "trials to compute site Q amplitudes"
			
		else
			
			amps = Q + gnoise( Q * CVQ2 * sqrtN )
			
		endif
		
	endif
	
	WaveStats /Q amps
	
	Print "Average site Q amplitude =", V_avg, "±", V_sdev
	Print "CVQ2 =", abs( V_sdev * sqrtN / V_avg )
	
	return sf + wName
	
End // NMPulseGCBinomSynSiteAmps

//****************************************************************
//****************************************************************

Function /S NMPulseGCTrainCall()

	Variable useExisting, stdSelect
	String wavePrefix, wList, std2
	String AMPAmodel, NMDAmodel
	
	String df = NMPulseDF
	String sf = NMPulseSubfolder()
	
	String title = "Pulse GC Synaptic Conductance Train"
	
	Variable numWaves = NumVarOrDefault( df + "NumWaves", 100 )
	numWaves = NumVarOrDefault( sf + "NumWaves", numWaves )
	
	Variable dx = NumVarOrDefault( df + "DeltaX", 0.005 )
	dx = NumVarOrDefault( sf + "DeltaX", dx )
	
	Variable waveLength = NumVarOrDefault( df + "WaveLength", 8 )
	waveLength = NumVarOrDefault( sf + "WaveLength", waveLength )
	
	if ( ( numWaves == NumWavesDefault ) && ( dx == DeltaxDefault ) && ( waveLength == WaveLengthDefault ) )
		numWaves = 1
		dx = 0.01
		waveLength = 1000
	endif
	
	numWaves = max( numWaves, 1 )
	
	Prompt numWaves, "number of waves to compute:"
	Prompt dx, "wave sample interval (delta-x):"
	Prompt waveLength, "wave length:"

	String type = StrVarOrDefault( df + "Prompt_GCTrainType", "AMPA" )
	String STPmodel = StrVarOrDefault( df + "Prompt_GCTrainSTP", "RP" )
	Variable freq = NumVarOrDefault( df + "Prompt_GCTrainFreq", 0.03 ) // kHz
	Variable random = 1 + NumVarOrDefault( df + "Prompt_GCTrainRandom", 1 )
	Variable numInputs = NumVarOrDefault( df + "Prompt_GCTrainNumInputs", 4 )
	
	strswitch( STPmodel )
		case "DF":
			stdSelect = 1
			break
		default:
			stdSelect = 2
			break
	endswitch
	
	Prompt type, "conductance type:", popup "AMPA;NMDA;"
	Prompt stdSelect, "plasticity model:", popup "DF (Rothman 2012);RP (Billings 2014);"
	Prompt freq, "frequency of input train (kHz):"
	Prompt random, "input intervals:", popup "fixed;random;"
	Prompt numInputs, "input trains per wave:"
	
	DoPrompt title, numWaves, dx, waveLength
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	SetNMvar( sf + "NumWaves", numWaves )
	SetNMvar( sf + "DeltaX", dx )
	SetNMvar( sf + "WaveLength", waveLength )
	
	DoPrompt title, type, stdSelect, freq, random, numInputs
	
	if ( V_flag == 1 )
		return "" // cancel
	endif
	
	switch( stdSelect )
		case 1:
			STPmodel = "DF"
			AMPAmodel = "Rothman"
			NMDAmodel = "Rothman"
			break
		case 2:
			STPmodel = "RP"
			AMPAmodel = "Billings"
			NMDAmodel = "Billings"
			break
		default:
			return ""
	endswitch
	
	random -= 1
	
	SetNMstr( df + "Prompt_GCTrainType", type )
	SetNMstr( df + "Prompt_GCTrainSTP", STPmodel )
	SetNMvar( df + "Prompt_GCTrainFreq", freq )
	SetNMvar( df + "Prompt_GCTrainRandom", random )
	SetNMvar( df + "Prompt_GCTrainNumInputs", numInputs )
	SetNMvar( df + "Prompt_GCTrainNumWaves", numWaves )
	
	wavePrefix = "PU_Ran" + num2istr( round( freq * 1000 ) ) + "Hz_w0"
	
	wList = WaveList( wavePrefix + "*", ";", "" )
	
	if ( random && ItemsInList( wList ) > 0 )
	
		useExisting = 2
	
		Prompt useExisting, "using existing waves of pulse times if they exist?", popup "no;yes;"
		DoPrompt title, useExisting
	
		if ( V_flag == 1 )
			return "" // cancel
		endif
		
		useExisting -= 1
		
	endif
	
	return NMPulseGCTrain( numWaves = numWaves, dx = dx, waveLength = waveLength, type = type, AMPAmodel = AMPAmodel, NMDAmodel = NMDAmodel, STPmodel = STPmodel, freq = freq, random = random, numInputs = numInputs, numWaves = numWaves, useExistingRanTrains = useExisting, history = 1 )

End // NMPulseGCTrainCall

//****************************************************************
//****************************************************************

Function /S NMPulseGCTrain( [ numWaves, dx, waveLength, type, AMPAmodel, NMDAmodel, STPmodel, freq, random, numInputs, useExistingRanTrains, update, history ] )
	Variable numWaves, dx, waveLength
	String type // "AMPA" or "NMDA"
	String AMPAmodel // "Digregorio" or "Rothman" or "Billings" // 2002 or 2012 or 2014
	String NMDAmodel // "Rothman" or "Billings"
	String STPmodel // "DF" for Rothman or "RP" for Billings
	Variable freq
	Variable random
	Variable numInputs
	
	Variable useExistingRanTrains
	Variable update
	Variable history
	
	Variable icnt, wcnt, amp1, amp2, pinf, RPmodel, BillingsModel, normValue
	Variable AMPAnorm
	String sf, wavePrefix, wName, wList = ""
	String trainList, trainList2, paramList, paramList2, paramList3
	String directSTPlist, spillSTPlist, nmdaSTPlist 
	
	Variable timeLimit = waveLength - 50
	
	Variable amp = 0.63
	
	String df = NMPulseDF()
	
	if ( ParamIsDefault( numWaves ) || ( numWaves <= 0 ) )
		numWaves = 1
	endif
	
	if ( ParamIsDefault( dx ) || ( numWaves <= 0 ) )
		dx = 0.01
	endif
	
	if ( ParamIsDefault( waveLength ) || ( waveLength <= 0 ) )
		waveLength = 1000
	endif
	
	if ( ParamIsDefault( type ) )
		type = "AMPA"
	endif
	
	if ( !StringMatch( type, "AMPA" ) && !StringMatch( type, "NMDA" ) )
		return "" // unknown type
	endif
	
	wavePrefix = "g" + type
	
	if ( ParamIsDefault( AMPAmodel ) )
		AMPAmodel = "Rothman"
	endif
	
	if ( ParamIsDefault( NMDAmodel ) )
		NMDAmodel = "Rothman"
	endif
	
	if ( ParamIsDefault( STPmodel ) )
		STPmodel = "DF"
	endif
	
	if ( ParamIsDefault( freq ) )
		freq = 0.01 // kHz
	endif
	
	if ( ParamIsDefault( numInputs ) )
		numInputs = 4
	endif
	
	if ( ParamIsDefault( update ) )
		update = 1
	endif
	
	if ( history )
		NMCommandHistory( "" )
	endif
	
	SetNMstr( df + "CurrentPrefixPulse", wavePrefix )
	
	NMPulseConfigRemove( all=1 )
	
	NMPulseCheck()
	
	sf = NMPulseSubfolder()
	
	SetNMvar( sf + "NumWaves", numWaves )
	SetNMvar( sf + "WaveLength", waveLength )
	SetNMvar( sf + "DeltaX", dx )
	SetNMstr( sf + "Xunits", NMXunits )
	SetNMstr( sf + "Yunits", "nS" )
	
	STRUCT NMPulseTrain t
	
	if ( random )
		t.type = ""
	else
		t.type = "fixed"
	endif
	
	t.tbgn = -inf
	t.tend = inf
	t.interval = 1 / freq
	t.refrac = 1
	
	trainList = NMPulseTrainParamList( t )
	trainList2 = trainList
	
	strswitch( AMPAmodel )
		case "Digregorio":
			AMPAnorm = 1.12551 // THE WAVEFORMS ARE NORMALIZED???
		case "Rothman":
			AMPAnorm = 1.16655 // THE WAVEFORMS ARE NORMALIZED???
			break
		case "Billings":
			AMPAnorm = 1
			break
		default:
			return ""
	endswitch
	
	strswitch( STPmodel )
		case "DF":
			directSTPlist = NMPulseTrainDF_GC_AMPAdirect()
			spillSTPlist = NMPulseTrainDF_GC_AMPAspill()
			nmdaSTPlist = NMPulseTrainDF_GC_NMDA()
			RPmodel = 0
			break
		case "RP":
			directSTPlist = NMPulseTrainRP_GC_AMPAdirect()
			spillSTPlist = NMPulseTrainRP_GC_AMPAspill()
			nmdaSTPlist = NMPulseTrainRP_GC_NMDA()
			RPmodel = 1
			break
		default:
			return ""
	endswitch
	
	for ( wcnt = 0 ; wcnt < numWaves; wcnt += 1 )
	
		for ( icnt = 0 ; icnt < numInputs ; icnt += 1 )
		
			if ( random )
		
				wName = "PU_Ran" + num2istr( round( freq * 1000 ) ) + "Hz_w" + num2istr( wcnt ) + "i" + num2istr( icnt )
				
				if ( !WaveExists( $wName ) || !useExistingRanTrains )
					NMPulseTrainRandomTimes( "", wName, trainList, timeLimit )
				endif
				
				if ( !WaveExists( $ wName ) )
					continue
				endif
				
				wList += wName + ";"
				
				trainList2 = "train=" + wName + ";"
			
			endif
			
			if ( StringMatch( type, "AMPA" ) )
			
				// direct
			
				amp1 = amp / AMPAnorm
				
				if ( RPmodel )
				
					pinf = str2num( StringByKey( "Pinf", directSTPlist, "=", ";" ) )
					
					if ( ( numtype( pinf ) == 0 ) && ( pinf > 0 ) && ( pinf < 1 ) )
						amp1 /= pinf
					endif
					
				endif
				
				amp2 = amp1
			
				paramList = "wave=" + num2istr( wcnt ) + ";"
				paramList += trainList2
				
				paramList2 = paramList
				
				strswitch( AMPAmodel )
					case "Rothman":
						paramList += NMPulseSynExp4_GC_AMPAdirect( model=AMPAmodel, amp=amp2 )
						paramList += directSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						break
					case "Billings":
						paramList += NMPulseExp_GC_AMPAdirect( select = 0 )
						paramList += directSTPlist
						paramList2 += NMPulseExp_GC_AMPAdirect( select = 1 )
						paramList2 += directSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						NMPulseConfigAdd( paramList2, history = 1 )
						break
					default:
						return ""
				endswitch
				
				// spillover
				
				amp1 *= 0.34 // Rothman 2016
				
				if ( RPmodel )
				
					pinf = str2num( StringByKey( "Pinf", spillSTPlist, "=", ";" ) )
					
					if ( ( numtype( pinf ) == 0 ) && ( pinf > 0 ) && ( pinf < 1 ) )
						amp1 /= pinf
					endif
					
				endif
				
				amp2 = amp1
				
				paramList = "wave=" + num2istr( wcnt ) + ";"
				paramList += trainList2
				
				paramList2 = paramList
				paramList3 = paramList
				
				strswitch( AMPAmodel )
					case "Rothman":
						paramList +=  NMPulseSynExp4_GC_AMPAspill( model=AMPAmodel, amp=amp2 )
						paramList += spillSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						break
					case "Billings":
						paramList += NMPulseExp_GC_AMPAspill( select = 0 )
						paramList += spillSTPlist
						paramList2 += NMPulseExp_GC_AMPAspill( select = 1 )
						paramList2 += spillSTPlist
						paramList3 += NMPulseExp_GC_AMPAspill( select = 2 )
						paramList3 += spillSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						NMPulseConfigAdd( paramList2, history = 1 )
						NMPulseConfigAdd( paramList3, history = 1 )
						break
					default:
						return ""
				endswitch
			
			elseif ( StringMatch( type, "NMDA" ) )
			
				paramList = "wave=" + num2istr( wcnt ) + ";"
				paramList += trainList2
				
				paramList2 = paramList
				
				strswitch( NMDAmodel )
					case "Rothman":
						paramList += NMPulseSynExp4_GC_NMDA( amp=amp )
						paramList += nmdaSTPlist
						break
					case "Billings":
						paramList += NMPulseExp_GC_NMDA( select = 0 )
						paramList += nmdaSTPlist
						paramList2 += NMPulseExp_GC_NMDA( select = 1 )
						paramList2 += nmdaSTPlist
						NMPulseConfigAdd( paramList, history = 1 )
						NMPulseConfigAdd( paramList2, history = 1 )
						break
					default:
						return ""
				endswitch
			
			endif
		
		endfor
	
	endfor
	
	if ( update )
		NMPulseUpdate()
	endif
	
	return wList

End // NMPulseGCTrain

//****************************************************************
//****************************************************************


