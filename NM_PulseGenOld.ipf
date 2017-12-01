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
//	OLD Pulse Generator Functions
//
//****************************************************************
//****************************************************************

Constant NMPulseGenEntries = 12

//****************************************************************
//****************************************************************

Structure NMPulseEntryOld

	Variable shapeNum, waveNum, waveNumD
	Variable amp, onset, width, tau2
	Variable ampD, onsetD, widthD, tau2D

EndStructure

//****************************************************************
//****************************************************************

Function PulseShapeNum( shapeName )
	String shapeName
	
	strswitch( shapeName )
	
		case "square":
			return 1
		case "ramp":
			return 2
		case "alpha":
			return 3
		case "exp":
			return 4
		case "sine":
			return 30
		case "cosine":
			return 31
		case "other":
			return 5 // 5 to 29
	endswitch
	
	return Nan
	
End // PulseShapeNum

//****************************************************************
//****************************************************************

Function /S PulseShape( df, shapeNum ) // convert shape number to name
	String df // data folder
	Variable shapeNum
	
	String pname
	
	switch( shapeNum )
	
		case 1:
			return "square"
		case 2:
			return "ramp"
		case 3:
			return "alpha"
		case 4:
			return "exp" // used to be "2-exp"
		case 30:
			return "sin"
		case 31:
			return "cos"
			
		default:
			
			if ( ( shapeNum >= 5 ) && ( shapeNum <= 29 ) )
				
				pname = StrVarOrDefault( df + "UserPulseName" + num2istr( shapeNum ), "" )
				
				if ( strlen( pname ) == 0 )
					pname = StrVarOrDefault( df + "UserPulseName", "" )
				endif
	
				return pname
				
			endif
			
	endswitch
	
	return ""
	
End // PulseShape

//****************************************************************
//****************************************************************

Function PulseSave(df, wPrefix, pulseNum, sh, wn, wnd, on, ond, am, amd, wd, wdd, t2, t2d)
	String df // data folder
	String wPrefix // wave prefix
	Variable pulseNum // (-1) dont care, append
	Variable sh, wn, wnd, on, ond, am, amd, wd, wdd, t2, t2d

	String wname = PulseWaveName(df, wPrefix)
	
	if ( strlen( wname ) == 0 )
		return NM2Error( 21, "wname", wname )
	endif

	if (!WaveExists($wname))
		Make /N=0 $(wname) // make pulse parameter wave
	endif
	
	Wave Pulse = $wname
	
	if (pulseNum == -1)
		pulseNum = numpnts(Pulse) / NMPulseGenEntries
	endif
		
	if ((pulseNum+1)*NMPulseGenEntries > numpnts(Pulse))
		Redimension /N=((pulseNum+1)*NMPulseGenEntries) Pulse
	endif
	
	Pulse[PulseNum*NMPulseGenEntries+1]=sh // shape
	Pulse[PulseNum*NMPulseGenEntries+2]=wn // wave num
	Pulse[PulseNum*NMPulseGenEntries+3]=wnd // wave num delta
	Pulse[PulseNum*NMPulseGenEntries+4]=on // onset
	Pulse[PulseNum*NMPulseGenEntries+5]=ond // onset delta
	Pulse[PulseNum*NMPulseGenEntries+6]=am // amplitude
	Pulse[PulseNum*NMPulseGenEntries+7]=amd // amp delta
	Pulse[PulseNum*NMPulseGenEntries+8]=wd // width
	Pulse[PulseNum*NMPulseGenEntries+9]=wdd // width delta
	Pulse[PulseNum*NMPulseGenEntries+10]=t2 // tau2
	Pulse[PulseNum*NMPulseGenEntries+11]=t2d // tau2 delta
	
	Pulse[0,;NMPulseGenEntries] = -x/NMPulseGenEntries // set delimiters
	
End // PulseSave

//****************************************************************
//****************************************************************

Function PulseClear(df, wPrefix, pulseNum) // clear pulse waves
	String df // data folder
	String wPrefix // wave prefix
	Variable pulseNum // (-1) for all
	
	Variable icnt
	String pname, wname = PulseWaveName(df, wPrefix)

	if (!WaveExists($wname))
		return 0 // "pulse" wave does not exist
	endif
	
	Wave Pulse = $wname
	
	if (pulseNum == -1) // clear all
	
		Redimension /N=0 Pulse
		
		KillStrings /Z $df+"UserPulseName"
		
		for (icnt = 5; icnt < 25; icnt += 1)
			KillStrings /Z $(df+"UserPulseName"+num2istr(icnt))
		endfor
	
	else
	
		DeletePoints PulseNum*NMPulseGenEntries,NMPulseGenEntries, Pulse
		
	endif
	
	Pulse[0,;NMPulseGenEntries] = -x/NMPulseGenEntries // reset delimiters

End // PulseClear

//****************************************************************
//****************************************************************

Function PulseCountConfigs(df, wPrefix) // count number of pulse configs
	String df // data folder
	String wPrefix // wave prefix
	
	String wname = PulseWaveName(df, wPrefix)
	
	if (!WaveExists($wname))
		return 0
	endif
	
	return numpnts($wname) / NMPulseGenEntries
	
End // PulseCountConfigs

//****************************************************************
//****************************************************************

Function /S PulseWavesMake(df, wPrefix, numWaves, npnts, dt, scale, ORflag)
	String df // data folder where waves are to be made
	String wPrefix // wave prefix
	Variable numWaves, npnts, dt, scale
	Variable ORflag // (0) add (1) OR
	
	Variable icnt, jcnt, kcnt, klmt
	String wlist = ""

	if (!DataFolderExists(df))
		NewDataFolder $RemoveEnding( df, ":" ) // create data folder if it does not exist
	endif
	
	String wname = PulseWaveName(df, wPrefix)
	
	if ( strlen( wname ) == 0 )
		return NM2ErrorStr( 21, "wname", wname )
	endif

	if (!WaveExists($wname))
		Make /N=0 $wname // make pulse parameter wave
	endif
	
	Wave pv = $wname

	for (icnt = 0; icnt < numWaves; icnt += 1) // loop through waves
	
		wname = df + wPrefix + "_" + num2istr(icnt)
	
		if (!WaveExists($wname))
			Make /N=(npnts) $wname = 0
		elseif (numpnts($wname) != npnts)
			Redimension /N=(npnts) $wname
		endif
		
		Setscale /P x 0, dt, $wname
		
		wlist = AddListItem(wPrefix + "_" + num2istr(icnt), wlist, ";", inf)
	
		Wave pwave = $wname
		
		pwave = 0
	
		for (jcnt = 0; jcnt < numpnts(pv); jcnt += NMPulseGenEntries) // loop through pulses
		
			if ( jcnt+11 >= numpnts( pv ) )
				break
			endif
		
		 	if (pv[jcnt + 3] > 0) // WaveNumD
		 		klmt = numWaves
		 	else
		 		klmt = 1
		 	endif
		 	
			for (kcnt = 0; kcnt < klmt; kcnt += 1)
			
				if (pv[jcnt + 2] + kcnt*pv[jcnt + 3] == icnt)
				
					PulseCompute(df,npnts,dt,pv[jcnt+1],pv[jcnt+4]+icnt*pv[jcnt+5],pv[jcnt+6]+icnt*pv[jcnt+7],pv[jcnt+8]+icnt*pv[jcnt+9],pv[jcnt+10]+icnt*pv[jcnt+11])
					
					Wave PG_PulseWave = $(df+"PG_PulseWave")
					
					if ( ORflag )
						pwave = pwave || PG_PulseWave // OR pulses
					else
						pwave += PG_PulseWave // add pulses
					endif
					
				endif
			endfor
			
		endfor
		
		pwave *= scale
	
	endfor
	
	KillWaves /Z PG_PulseWave
	
	return wlist
	
End // PulseWavesMake

//****************************************************************
//****************************************************************

Function PulseCompute(df, npnts, dt, shape, onset, amp, tau1, tau2) // create pulse shape wave
	String df // data folder
	Variable npnts, dt
	Variable shape, onset, amp, tau1, tau2
	
	Variable pbgn, pend, pmax, clipEnd = 0
	
	String wname
	
	Make /O/N=(npnts) $(df+"PG_PulseWave") // the output wave
	
	Wave PG_PulseWave = $(df+"PG_PulseWave")
	
	PG_PulseWave = 0
	
	pmax = numpnts( PG_PulseWave ) - 1
	
	tau2 = abs( tau2 )
	
	switch(shape)
	
		case 1: // square
			PG_PulseWave = 1
			clipEnd = 1
			break
			
		case 2: // ramp
			if ( tau1 > 0 )
				PG_PulseWave = ( x * dt - onset ) / tau1 // positive ramp
			elseif ( tau1 < 0 )
				tau1 = abs( tau1 )
				PG_PulseWave = 1 - ( x * dt - onset ) / tau1 // negative ramp
			endif
			clipEnd = 1
			break
			
		case 3: // alpha wave
			tau1 = abs( tau1 )
			PG_PulseWave = (x*dt-onset)*exp((onset-x*dt)/tau1)
			break
			
		case 4: // sum of 2 exponentials
			tau1 = abs( tau1 )
			//PG_PulseWave = (1 - exp((onset-x*dt)/tau1)) * exp((onset-x*dt)/tau2)
			PG_PulseWave = -exp((onset-x*dt)/tau1) + exp((onset-x*dt)/tau2)
			break
			
		case 30: // sine
			PG_PulseWave = sin( 2 * pi * ( x * dt - onset) / tau2 )
			clipEnd = 1
			break
			
		case 31: // cosine
			PG_PulseWave = cos( 2 * pi * ( x * dt - onset) / tau2 )
			clipEnd = 1
			break
			
		default: // other, user-defined pulse (5 to 29)
		
			if ( ( shape >= 5 ) && ( shape <= 29 ) )
		
				wname = StrVarOrDefault(df+"UserPulseName", "") // OLD NAME
				
				if (!WaveExists($(df+wname)))
					wname = StrVarOrDefault(df+"UserPulseName"+num2istr(shape), "") // NEW NAME
				endif
				
				if ( WaveExists($df+wname) )
					Wave yourpulse = $df+wname
					pend = numpnts( yourpulse ) - 1
					yourpulse[ pend, pend ] = 0 // make sure last point is zero
					PG_PulseWave = yourpulse
					Rotate (onset/dt), PG_PulseWave
				endif
			
			endif
			
			break
			
	endswitch
	
	pbgn = 0
	pend = min( ( onset / dt ), pmax )
	
	if ( pend > pbgn )
		PG_PulseWave[ pbgn, pend ] = 0 // zero before onset time
	endif
	
	if ( clipEnd )
	
		pbgn =  min( ( ( onset + abs( tau1 ) ) / dt ) + 1, pmax )
		
		if ( pmax > pbgn )
			PG_PulseWave[ pbgn, pmax ] = 0 // zero after pulse
		endif
	
	endif
	
	Wavestats /Q/Z PG_PulseWave
	
	if (V_max != 0)
		PG_PulseWave *= amp / V_max // set amplitude
	endif
	
	Setscale /P x 0, dt, PG_PulseWave

End // PulseCompute

//****************************************************************
//****************************************************************

Function PulseTrain(df, wPrefix, wbgn, wend, winc, tbgn, tend, type, intvl, refrac, shape, amp, width, tau2, continuous, wName)
	String df // data folder
	String wPrefix // wave prefix
	
	Variable wbgn, wend // wave number begin, end
	Variable winc // wave increment
	Variable tbgn, tend // window begin/end time
	Variable type // (1) fixed (2) random (3) from wave
	Variable intvl // inter-pulse interval
	Variable refrac // refractory period for random train
	Variable shape // pulse shape
	Variable amp // pulse amplitude
	Variable width // pulse width or time constant
	Variable tau2 // decay time constant for 2-exp
	Variable continuous // if waves are to be treated as continuous (0) no (1) yes
	
	String wName // wave name, for type 3
	
	Variable onset, tlast, wcnt, pcnt, hold
	
	switch(type)
		case 1:
			return PulseTrainFixed(df, wPrefix, wbgn, wend, winc, tbgn, tend, intvl, shape, amp, width, tau2, continuous)
		case 2:
			return PulseTrainRandom(df, wPrefix, wbgn, wend, winc, tbgn, tend, intvl, refrac, shape, amp, width, tau2, continuous)
		case 3:
			return PulseTrainFromWave(df, wPrefix, wbgn, wend, winc, tbgn, tend, shape, amp, width, tau2, continuous, wName)
	endswitch
	
	return -1

End // PulseTrain

//****************************************************************
//****************************************************************

Function PulseTrainFixed(df, wPrefix, wbgn, wend, wdelta, tbgn, tend, intvl, shape, amp, width, tau2, continuous)
	String df // data folder
	String wPrefix // wave prefix
	
	Variable wbgn, wend // wave number begin, end
	Variable wdelta // wave delta
	Variable tbgn, tend // window begin/end time
	Variable intvl // inter-pulse interval
	Variable shape // pulse shape
	Variable amp // pulse amplitude
	Variable width // pulse width or time constant
	Variable tau2 // decay time constant for 2-exp
	Variable continuous // if waves are to be treated as continuous (0) no (1) yes
	
	Variable wcnt, onset, pcnt, plimit = 5 + ceil((tend - tbgn) / intvl)
	
	for (pcnt = 0; pcnt < plimit; pcnt += 1)
	
		onset = tbgn + intvl * pcnt
		
		if ((onset >= tbgn) && (onset < tend))
			PulseSave(df, wPrefix, -1, shape, wbgn, wdelta, onset, 0, amp, 0, width, 0, tau2, 0)
		endif
		
	endfor
	
End // PulseTrainFixed

//****************************************************************
//****************************************************************

Function PulseTrainRandom(df, wPrefix, wbgn, wend, wdelta, tbgn, tend, intvl, refrac, shape, amp, width, tau2, continuous)
	String df // data folder
	String wPrefix // wave prefix
	
	Variable wbgn, wend // wave number begin, end
	Variable wdelta // wave increment
	Variable tbgn, tend // window begin/end time
	Variable intvl // inter-pulse interval
	Variable refrac // refractory period for random train
	Variable shape // pulse shape
	Variable amp // pulse amplitude
	Variable width // pulse width or time constant
	Variable tau2 // decay time constant for 2-exp
	Variable continuous // if waves are to be treated as continuous (0) no (1) yes
	
	Variable onset, wcnt, tlast, pcnt, plimit = 99 + ((tend - tbgn) / intvl)
	
	wdelta = 0
	
	for ( wcnt = wbgn ; wcnt <= wend ; wcnt += 1 )
	
		tlast = tbgn
		pcnt = 0
		
		do // add pulses
	
			onset = tlast - ln(abs(enoise(1))) * intvl
			
			if ((onset > tlast + refrac) && (onset < tend))
				PulseSave(df, wPrefix, -1, shape, wcnt, wdelta, onset, 0, amp, 0, width, 0, tau2, 0)
				tlast = onset
				pcnt += 1
			endif
			
		while ((onset < tend) && (pcnt < plimit))
		
	endfor

End // PulseTrainRandom

//****************************************************************
//****************************************************************

Function PulseTrainFromWave(df, wPrefix, wbgn, wend, winc, tbgn, tend, shape, amp, width, tau2, continuous, wName)
	String df // data folder
	String wPrefix // wave prefix
	
	Variable wbgn, wend // wave number begin, end
	Variable winc // wave increment
	Variable tbgn, tend // window begin/end time
	Variable shape // pulse shape
	Variable amp // pulse amplitude
	Variable width // pulse width or time constant
	Variable tau2 // decay time constant for 2-exp
	Variable continuous // if waves are to be treated as continuous (0) no (1) yes
	
	String wName // wave name, for type 3
	
	Variable onset, tlast, wcnt, pcnt, plimit
	
	if (!WaveExists($wName))
		return -1
	endif
	
	Wave wtemp = $wName
	
	plimit = numpnts(wtemp) // wave of intervals
	
	winc = max(winc, 1)
	
	for (wcnt = wbgn; wcnt <= wend; wcnt += winc)
		
		tlast = tbgn
		
		for (pcnt = 0; pcnt < plimit; pcnt += 1)
	
			if (numtype(wtemp[pcnt]) == 0)
			
				onset = tlast + wtemp[pcnt]
			
				if ((onset > tlast) && (onset < tend))
					PulseSave(df, wPrefix, -1, shape, wcnt, winc, onset, 0, amp, 0, width, 0, tau2, 0)
					tlast = onset
				endif
				
			endif
			
		endfor
	
	endfor

End // PulseTrainFromWave

//****************************************************************
//****************************************************************