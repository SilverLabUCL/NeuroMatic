#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
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
//	NM functions for estimating 3D particle size and density from 2D projections using Keiding model for lost caps
//
//****************************************************************
//****************************************************************
//
//	Rothman JS, Borges-Merjane C, Holderith N, Jonas P, Silver RA
//	Validation of a stereological method for estimating particle size and density from 2D projections with high accuracy.
//	PLOS ONE 2023 (in press)
//	https://doi.org/10.1371/journal.pone.0277148
//	bioRxiv 25 Oct 2022
//	https://doi.org/10.1101/2022.10.21.513285
//
//****************************************************************
//****************************************************************
//
//	Keiding N, Jensen ST, Ranek L
//	Maximum likelihood estimation of the size distribution of liver cell nuclei from the observed distribution in a plane section.
//	Biometrics 1972 Sep;28(3):813-29
//	PMID: 5073254.
//  https://doi.org/10.2307/2528765
//
//****************************************************************
//****************************************************************
//
//	Wicksell SD
//	The corpuscle problem: a mathematical study of a biometric problem.
//	Biometrika. 1925 Jun;17(1/2): 84–99.
//	doi: 10.2307/2332027
//	Example 4
//
//****************************************************************
//****************************************************************
//
//	Nguyen TM, Thomas LA, Rhoades JL, Ricchi I, Yuan XC, Sheridan A, et al.
//	Structured cerebellar connectivity supports resilient pattern separation.
//	Nature. 2023 Jan 19; 613(7944):543-549.
//	doi: 10.1038/s41586-022-05471-w
//
//****************************************************************
//****************************************************************

// Below are G and F number lists containing histogram bin counts that are converted to PDFs

// Spleen follicles, Wicksell 1925
Static Constant Wicksell_T = 0.018 // mm // without magnification
Static Constant Wicksell_Magnification = 18
Static Constant Wicksell_G_BinWidth = 1
Static StrConstant Wicksell_G_Units = "mm"
Static StrConstant Wicksell_G = "0;0;52;146;197;210;184;143;95;57;31;15;7;4;2;1;0;0;"
Static StrConstant Wicksell_F = "5;14;38;72;151;194;172;143;96;57;31;15;6;3;2;1;0;0"
Static StrConstant WicksellFolder = "Wicksell"

// Liver cell nuclei, Keiding 1972
Static Constant Keiding_T = 6.5 //um
Static Constant Keiding_N = 500 // # diameters
Static Constant Keiding_Magnification = 2300
Static Constant Keiding_G_BinStart = 6000
Static Constant Keiding_G_BinWidth = 250
Static StrConstant Keiding_G_Units = "μm"
Static StrConstant Keiding_G_H0601 = "7;21;43;64;94;70;69;47;26;8;11;11;9;11;2;1;3;2;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;" // radii
Static StrConstant Keiding_G_H2003 = "0;0;9;22;78;121;96;75;24;6;7;5;6;14;15;10;2;2;1;0;1;1;1;2;1;1;0;0;0;0;0;0;0;"
Static StrConstant Keiding_G_H1037 = "0;1;5;10;18;24;43;61;65;62;60;37;30;17;15;11;8;6;7;2;0;5;5;2;0;2;0;1;2;1;0;0;0;"
Static StrConstant KeidingFolder = "Keiding1972"

// GC somata G(d) frequencies, confocal data, Rothman et al 2023
Static Constant GC_Somata_G_BinWidth = 0.3 // um
Static StrConstant GC_Somata_G_Units = "μm"
Static StrConstant GC_Somata_G_R1_SL1_1 = "0;0;0;0;0;0;0;0;2;0;6;2;10;23;22;23;24;64;67;122;95;93;51;25;5;2;2;0;0;0;0;0;"
Static StrConstant GC_Somata_G_R1_SL1_2 = "0;0;0;0;0;0;0;0;0;1;3;4;6;10;16;30;35;40;56;91;110;93;41;22;6;3;1;1;0;0;0;0;"
Static StrConstant GC_Somata_G_R1_SL2_1 = "0;0;0;0;0;0;0;0;0;3;0;6;9;18;22;30;45;67;95;86;56;42;12;11;1;1;1;0;1;0;0;0;"
Static StrConstant GC_Somata_G_R5_SL1_1 = "0;0;0;0;0;0;0;2;4;6;11;11;22;20;31;37;71;88;120;83;45;16;1;5;2;0;0;0;0;0;0;0;"
Static StrConstant GC_Somata_G_R5_SL2_1 = "0;0;0;0;0;0;0;1;1;3;5;18;19;21;22;39;54;103;115;77;34;14;7;2;3;1;0;1;0;0;0;0;"
Static StrConstant GC_Somata_G_R5_SL3_1 = "0;0;0;0;0;0;0;0;0;0;3;4;9;14;14;27;47;91;96;104;67;26;2;4;0;0;0;0;0;0;0;0;"
Static StrConstant GC_Somata_G_R6_SL1_1 = "0;0;0;0;0;0;0;0;6;14;12;25;24;30;31;37;65;103;81;54;28;14;4;0;0;0;0;0;0;0;0;0;"
Static StrConstant GC_Somata_G_R6_SL2_1 = "0;0;0;0;0;0;0;0;1;4;6;4;9;21;33;42;75;115;105;52;24;3;0;0;0;0;0;0;0;0;0;0;"
Static StrConstant GC_Somata_G_R6_SL2_2 = "0;0;0;0;0;0;0;0;2;4;4;3;4;6;19;37;75;108;126;75;33;10;2;0;0;0;0;0;0;0;0;0;"
Static StrConstant GC_Somata_T_List = "R1.SL1.1=1.6829478;R1.SL1.2=1.7561194;R1.SL2.1=1.8359430;R5.SL1.1=1.3927844;R5.SL2.1=1.5534902;R5.SL3.1=1.8359430;R6.SL1.1=2.6927164;R6.SL2.1=1.5534902;R6.SL2.2=1.5534902;"
Static StrConstant GC_Somata_Folder = "GC_Somata"

// GC nuclei G(d) frequencies, TEM data, Rothman et al 2023
Static Constant GC_Nuclei_G_BinWidth = 0.25 // um
Static StrConstant GC_Nuclei_G_Units = "μm"
Static StrConstant GC_Nuclei_G_M15_All = "0;0;0;0;0;3;3;8;12;21;23;28;17;33;44;44;55;61;61;70;26;8;1;1;0;0;0;"
Static StrConstant GC_Nuclei_G_M18_All = "0;0;0;0;0;0;2;5;7;9;22;18;14;17;29;37;31;45;60;59;56;47;25;4;0;0;0;"
Static StrConstant GC_Nuclei_G_M19_All = "0;0;0;0;0;1;8;7;15;17;18;16;21;20;33;33;32;50;62;36;32;12;2;1;0;0;0;"
Static StrConstant GC_Nuclei_G_M21_All = "0;0;0;0;1;7;6;6;18;19;29;28;29;32;34;70;63;57;41;14;4;1;1;0;0;0;0;"
Static Constant GC_Nuclei_T = 0.060 // um
Static StrConstant GC_Nuclei_Folder = "GC_Nuclei"

// GC nuclei G(d) frequencies, TEM data of Nguyen et al 2023, Fig S9 in S1_File.pdf
Static StrConstant GC_Nuclei_G_Nguyen = "0;0;0;0;1;4;9;7;12;13;14;11;20;20;15;26;25;21;19;21;36;47;50;50;59;60;52;54;27;7;4;1;1;1;0;1;0;0;0;0;"
Static StrConstant GC_Nuclei_F_Nguyen = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;2;5;11;14;22;21;19;6;4;0;1;0;0;1;0;0;0;0;"
Static Constant GC_Nuclei_Nguyen_T = 0.040 // um
Static StrConstant GC_Nuclei_Nguyen_Folder = "GC_Nuclei_Nguyen"
Static Constant GC_Nuclei_F_Nguyen_MN = 6.72909252 // um // measured
Static Constant GC_Nuclei_F_Nguyen_SD = 0.50875555 // um // measured

// MFT vesicle G(d) frequencies, TEM data, Rothman et al 2023
Static Constant MFT_Vesicles_G_TEM_BinWidth = 2 // nm
Static StrConstant MFT_Vesicles_G_TEM_Units = "nm"
Static StrConstant MFT_Vesicles_G_M15_45 = "0;0;0;0;0;0;0;0;0;0;0;1;0;0;1;0;1;1;3;22;25;34;47;48;41;32;28;9;5;2;1;2;1;1;0;1;1;1;0;1;0;0;0;0;"
Static StrConstant MFT_Vesicles_G_M15_48 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2;0;3;9;26;38;60;38;33;26;20;5;3;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;"
Static StrConstant MFT_Vesicles_G_M18_03 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;2;6;10;29;39;36;37;12;14;2;1;1;0;0;0;1;0;0;0;0;0;0;0;0;0;0;"
Static StrConstant MFT_Vesicles_G_M18_10 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;1;10;11;23;34;25;22;11;5;3;1;1;0;0;1;1;0;0;2;0;0;0;0;0;0;0;"
Static StrConstant MFT_Vesicles_G_M19_26 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3;1;3;4;23;49;75;71;51;37;20;11;3;3;0;2;1;0;1;0;0;0;0;0;0;0;0;0;0;"
Static StrConstant MFT_Vesicles_G_M19_34 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;4;3;9;16;66;93;85;59;41;27;8;10;0;3;1;2;1;0;0;0;0;0;0;0;0;0;0;0;0;"
Static StrConstant MFT_Vesicles_G_M21_04 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2;4;11;20;32;43;32;26;16;10;1;2;2;1;2;0;2;0;0;0;0;0;0;0;0;0;0;"
Static StrConstant MFT_Vesicles_G_M21_19 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;2;4;2;8;16;26;52;40;33;26;7;4;8;3;2;3;0;0;1;0;1;0;0;0;1;0;0;0;"
Static Constant MFT_Vesicles_TEM_T = 60 // nm
Static StrConstant MFT_Vesicles_TEM_Folder = "MFT_Vesicles_TEM"

// MFT vesicle G(d) frequencies, ET data, Rothman et al 2023
Static Constant MFT_Vesicles_G_ET_BinWidth = 1 // nm
Static StrConstant MFT_Vesicles_G_ET_Units = "nm"
Static StrConstant MFT_Vesicles_G_ET10 = "0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;2;0;1;1;7;6;12;25;23;31;29;46;66;67;88;90;121;151;165;202;197;233;284;357;397;421;435;512;497;462;441;403;309;228;200;167;138;100;60;53;23;23;3;2;2;1;0;0;0;"
Static StrConstant MFT_Vesicles_F_ET10 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;5;2;7;5;7;13;12;13;14;13;10;8;5;4;6;4;0;1;1;0;0;0;0;0;0;0;"
Static StrConstant MFT_Vesicles_G_ET11 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;8;12;20;32;59;92;155;173;224;282;302;402;440;460;537;645;678;768;879;964;983;978;1026;902;786;666;541;341;203;102;87;66;41;16;8;7;6;5;1;6;5;4;1;0;0;0;0;0;0;"
Static StrConstant MFT_Vesicles_F_ET11 = "  0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;2;2;5;18;20;14;35;28;25;26;21;15;4;8;3;3;0;1;0;0;1;0;0;0;0;1;0;0;0;0;0;0;0;"
Static Constant MFT_Vesicles_ET_T = 0 // nm
Static StrConstant MFT_Vesicles_ET_Folder = "MFT_Vesicles"
Static Constant MFT_Vesicles_F_ET10_MN = 46.0006974 // nm // measured
Static Constant MFT_Vesicles_F_ET10_SD = 4.0356605 // nm // measured
Static Constant MFT_Vesicles_ET10_Phi_MN = 40.9923688 // degrees // measured
Static Constant MFT_Vesicles_F_ET11_MN = 42.9372104 // nm // measured
Static Constant MFT_Vesicles_F_ET11_SD = 3.4026290 // nm // measured
Static Constant MFT_Vesicles_ET11_Phi_MN = 41.515274 // degrees // measured

// D3D simulations, Rothman et al 2023, Figs 3 & 4
Static Constant D3D_F_MN = 46 // nm
Static Constant D3D_F_SD = 4 // nm
Static Constant D3D_G_BinWidth = 2 // nm
Static StrConstant D3D_G_Units = "nm"
Static StrConstant D3D_G_T0_P20_41 = "0;0;0;0;0;0;0;3;5;9;14;17;11;10;23;12;27;28;33;36;47;52;57;24;27;21;5;1;0;0;0;0;0;0;0;0;"
Static StrConstant D3D_G_T1_P70_41 = "0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;2;8;18;50;72;95;92;74;44;19;4;3;0;0;0;0;0;0;0;"
Static StrConstant D3D_Folder = "D3D_Sims"
Static Constant D3D_G_Convert2UD = 1
		
//**************************************************************** //

Menu "NeuroMatic"
	
	Submenu "Analysis"
	
	"-"

		Submenu "Keiding model for estimating particle size and density"
			"Keiding et al 1976", /Q, NMKeiding_Citation()
			"Rothman et al 2023", /Q, NMKeiding_Rothman2023_Citation()
			"-"
			"Compute Analytical G (Fig 3)", /Q, NMKeidingGaussMakeGCall()
			"Fit Keiding G (Fig S2)", /Q, NMKeiding_Fit_All( computeOriginalFits=1, graph=1 )
			"Fit Wicksell G (Fig S3)", /Q, NMKeiding_Wicksell_Fit( graph=1 )
			"Fit Simulated G (Fig 4)", /Q, NMKeiding_D3D_G_Fit( graph=1 )
			"Fit MFT Vesicle G ET11 (Fig 6)", /Q, NMKeiding_MFves_G_ET_Fit( "ET11", graph=1 )
			"Fit MFT Vesicle G ET10 (Fig S8)", /Q, NMKeiding_MFves_G_ET_Fit( "ET10", graph=1 )
			"Fit GC Nuclei G Nguyen (Fig S9)", /Q, NMKeiding_GCnuclei_Nguyen_G_Fit( graph=1 )
			"Fit GC Somata G (Fig 8)", /Q, NMKeiding_GCsoma_G_Fit()
			"Fit GC Nuclei G (Fig 8)", /Q, NMKeiding_GCnuclei_G_Fit()
			"Fit MFT Vesicle G TEM  (Fig 9)", /Q, NMKeiding_MFves_G_TEM_Fit()
			"-"
			"Convert Density to VF", /Q, NM_Convert_Density_To_VF()
			"Convert VF to Density", /Q, NM_Convert_VF_To_Density()
		End
	
	End
	
End

//**************************************************************** //

Function NMKeiding_Citation()

	NMHistory( NMQuotes( "Maximum likelihood estimation of the size distribution of liver cell nuclei from the observed distribution in a plane section." ) )
	NMHistory( "Keiding N, Jensen ST, Ranek L" )
	NMHistory( "Biometrics 1972 Sep;28(3):813-29" )
	NMHistory( "https://doi.org/10.2307/2528765" )

End // NMKeiding_Citation

//**************************************************************** //

Function NMKeiding_Rothman2023_Citation()

	NMHistory( NMQuotes( "Validation of a stereological method for estimating particle size and density from 2D projections with high accuracy." ) )
	NMHistory( "Rothman JS, Borges-Merjane C, Holderith N, Jonas P, Silver RA" )
	NMHistory( "PLOS ONE 2023 (in press)" )
	NMHistory( "https://doi.org/10.1371/journal.pone.0277148" )
	NMHistory( "bioRxiv 25 Oct 2022" )
	NMHistory( "https://doi.org/10.1101/2022.10.21.513285" )

End // NMKeiding_Rothman2023_Citation

//****************************************************************//
//
//	Functions for NM Fit tab
//
//****************************************************************//

Function NMKeidingCompute( wName, paramWaveName, select ) // execution call from NM Fit tab
	String wName, paramWaveName
	String select
	
	if ( !WaveExists( $wName ) || !WaveExists( $paramWaveName ) )
		return -1
	endif
	
	Wave wtemp = $wName
	Wave W_coef = $paramWaveName
	
	strswitch( select )
		case "Gauss":
			wtemp = NMKeidingGauss( W_coef, x )
			break
		case "Chi":
			wtemp = NMKeidingChi( W_coef, x )
			break
		case "Gamma":
			wtemp = NMKeidingGamma( W_coef, x )
			break
		default:
			return -1
	endswitch
	
	return 0
	
End // NMKeidingCompute

//****************************************************************//

Function NMKeidingGaussInit()

	Variable icnt, mn, stdvx, phi, xmin, xmax, xwidth
	
	Variable autoguess = NMFitVarGet( "KeidingGuessAuto" )
	Variable constraints = 0 // NMFitVarGet( "KeidingConstraints" )
	
	String wName = CurrentNMWaveName()
	String guess = NMFitWavePath( "guess" )
	String hold = NMFitWavePath( "hold" )
	String low = NMFitWavePath( "low" )
	String high = NMFitWavePath( "high" )
	
	if ( !WaveExists( $guess ) || !WaveExists( $hold ) )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return NaN
	endif
	
	Wave FT_guess = $guess
	Wave FT_hold = $hold
	
	FT_hold[ 4 ] = 1 // N // check this is held since it's not a real parameter
	FT_hold[ 5 ] = 1 // PhiCutoff // check this is held since it's not a real parameter
	FT_guess[ 5 ] = 0 // PhiCutoff // not a real parameter
	
	if ( NMKeidingPDFcheck() != 0 )
		return 0
	endif
	
	if ( !autoguess && !constraints )
		return 0
	endif
	
	String statsList = NM_PDFstats( wName, quiet = 1, make_MN_SD_Waves=0 )
	
	mn = str2num( StringByKey("mean", statsList, "=") )
	
	if ( numtype( mn ) != 0 )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return NaN
	endif
	
	stdvx = str2num( StringByKey("stdv", statsList, "=") )
	
	if ( numtype( stdvx ) != 0 )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return NaN
	endif
	
	xmin = str2num( StringByKey("xmin", statsList, "=") )
	xmax = str2num( StringByKey("xmax", statsList, "=") )
	xwidth = abs( xmax - xmin )
	
	phi = asin( xmin / mn ) * 180 / pi // degrees
	
	//Print "Fit NMKeidingGauss xmin =", xmin
	//Print "Fit NMKeidingGauss x0 guess =", x0, FT_hold[ 0 ]
	//Print "Fit NMKeidingGauss stdvx guess =", stdvx, FT_hold[ 1 ]
	//Print "Fit NMKeidingGauss phi guess =", phi, FT_hold[ 2 ]
	
	if ( autoguess )
	
		if ( FT_hold[ 0 ] != 1 )
			FT_guess[ 0 ] = mn
		endif
		
		if ( FT_hold[ 1 ] != 1 )
			FT_guess[ 1 ] = stdvx
		endif
		
		if ( FT_hold[ 2 ] != 1 )
			FT_guess[ 2 ] = phi
		endif
	
	endif
	
	if ( constraints )
	
		Wave FT_low = $low
		Wave FT_high = $high
	
		FT_low[ 0 ] = xmin
		FT_high[ 0 ] = xmax
		
		FT_low[ 1 ] = 0
		FT_high[ 1 ] = stdvx * 2
		
		FT_low[ 2 ] = 0 // degrees
		FT_high[ 2 ] = 90 // degrees
	
	endif
	
	return 0

End // NMKeidingGaussInit

//****************************************************************//

Function NMKeidingGauss(w,x) : FitFunc // based on NMKeidingChi from Keiding et al. 1972
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = KeidingGauss(x0,stdv,phi,T,N,phicutoff)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = STDVx
	//CurveFitDialog/ w[2] = phi
	//CurveFitDialog/ w[3] = T
	//CurveFitDialog/ w[4] = N
	//CurveFitDialog/ w[5] = phicutoff
	
	// number of diameters (N) used after fit to compute phi-cutoff via NMKeidingGaussPhiCutoff
	// computed phi-cutoff saved in w[5]
	
	Variable x_max, zeta_, radians
	Variable phi = w[2]
	Variable T = w[3]
	//Variable x_min = x
	//Variable options = 1 // DOES NOT WORK
	//Variable options = 2 // 2:	Gaussian Quadrature integration
	//Variable count = 0 // adaptive 
	
	if ( phi == 0 ) // Bach
		zeta_ = T + w[0]
		x_max = NumVarOrDefault( NMFitDF+"KeidingXmax", 100 ) // needs to be greater than x-max of data
	elseif ( phi == 90 ) // G = F
		return gauss( x, w[0], w[1] )
	else // Keiding
		radians = phi * pi / 180.0
		zeta_ = T + w[0] * cos(radians)
		x_max = x / sin(radians)
	endif
	
	Variable /G NMKeiding_Integrate_Xvalue = x 
	
	//Variable i1D = integrate1D(NMKeidingGaussIntegral, x_min, x_max, options, count, w)
	Variable i1D = integrate1D(NMKeidingGaussIntegral, x, x_max, 2, 0, w)
	//Variable i1D = integrate1D(NMKeidingGaussIntegral, x, x_max, 0, 30000, w) // need large count to match options = 2
	
	return ( T * Gauss(x, w[0], w[1]) + x * i1D ) / zeta_
	
End // NMKeidingGauss

//****************************************************************//

Function NMKeidingGaussIntegral(w, xVOI)
	Wave w
	// w[0] = mean
	// w[1] = stdv
	// w[2] = phi (not used)
	// w[3] = T (not used)
	// w[4] = N (not used)
	// w[5] = phicutoff (not used)
	Variable xVOI
	
	NVAR xvalue = NMKeiding_Integrate_Xvalue
	
	Variable xsd = sqrt(xVOI * xVOI - xvalue * xvalue)
	
	if (xsd == 0)
		xsd = 0.0000001 // avoid singularity
	endif
	
	return Gauss( xVOI, w[0], w[1] ) / xsd
	
End // NMKeidingGaussIntegral

//****************************************************************//

Function NMKeidingGauss3(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = KeidingGauss3(x0,stdv,phi,T,p1,p2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = X0
	//CurveFitDialog/ w[1] = STDVx
	//CurveFitDialog/ w[2] = phi
	//CurveFitDialog/ w[3] = T
	//CurveFitDialog/ w[4] = p1
	//CurveFitDialog/ w[5] = p2
	
	Variable x_max, zeta_
	Variable phi = w[2]
	Variable radians = phi * pi / 180.0
	Variable T = w[3]
	//Variable x_min = x
	//Variable options = 2 // 2:	Gaussian Quadrature integration
	//Variable count = 0 // adaptive
	
	Variable mn1 = w[0]
	Variable mn2 = mn1 * 2 ^ (1.0/3.0)
	Variable mn3 = mn2 * 2 ^ (1.0/3.0)
	Variable var2 = w[1] * w[1] * 2 ^ (2.0/3.0)
	Variable var3 = var2 * 2 ^ (2.0/3.0)
	Variable sd2 = sqrt(var2)
	Variable sd3 = sqrt(var3)
	
	//if ( !WaveExists( $"W_Coef2" ) )
		Make /D/O/N=2 W_Coef2, W_Coef3
	//endif
	
	W_Coef2[ 0 ] = mn2
	W_Coef2[ 1 ] = sd2
	
	W_Coef3[ 0 ] = mn3
	W_Coef3[ 1 ] = sd3
	
	Variable /G NMKeiding_Integrate_Xvalue = x
	
	Variable p3 = 1 - w[4] - w[5]
	
	//if ( p3 < 0 )
		//p3 = abs( p3 )
		//w[5] = 1 - w[4] - p3
	//endif
	
	Variable pp1 = w[4] / ( T + mn1 * cos(radians) )
	Variable pp2 = w[5] / ( T + mn2 * cos(radians) )
	Variable pp3 = p3 / ( T + mn3 * cos(radians) )
	Variable sumpp = pp1 + pp2 + pp3
	Variable q1 = pp1 / sumpp
	Variable q2 = pp2 / sumpp
	Variable q3 = pp3 / sumpp
	
	Variable qmn = q1 * mn1 + q2 * mn2 + q3 * mn3
	
	if ( phi == 0 ) // Bach
		zeta_ = T + qmn
		x_max = NumVarOrDefault( NMFitDF+"KeidingXmax", 100 ) // needs to be greater than x-max of data
	elseif ( phi == 90 ) // G = F
		return Gauss(x, mn1, w[1]) + Gauss(x, mn2, sd2) + Gauss(x, mn3, sd3)
	else // Keiding
		zeta_ = T + qmn * cos(radians)
		x_max = x / sin(radians)
	endif
	
	//Variable i1D = integrate1D(NMKeidingGaussIntegral, x_min, x_max, options, count, w)
	Variable i1D1 = integrate1D(NMKeidingGaussIntegral, x, x_max, 2, 0, w)
	Variable i1D2 = integrate1D(NMKeidingGaussIntegral, x, x_max, 2, 0, W_Coef2)
	Variable i1D3 = integrate1D(NMKeidingGaussIntegral, x, x_max, 2, 0, W_Coef3)
	
	Variable g1 = T * Gauss(x, mn1, w[1]) + x * i1D1
	Variable g2 = T * Gauss(x, mn2, sd2) + x * i1D2
	Variable g3 = T * Gauss(x, mn3, sd3) + x * i1D3
	
	return ( q1 * g1 + q2 * g2 + q3 * g3 ) / zeta_
	
End // NMKeidingGauss3

//****************************************************************//

Function NMKeidingChiInit()

	Variable icnt, mn, stdvx, phi, xmin, xmax, xwidth
	
	Variable autoguess = NMFitVarGet( "KeidingGuessAuto" )
	Variable constraints = 0 // NMFitVarGet( "KeidingConstraints" )
	
	String wName = CurrentNMWaveName()
	String guess = NMFitWavePath( "guess" )
	String hold = NMFitWavePath( "hold" )
	String low = NMFitWavePath( "low" )
	String high = NMFitWavePath( "high" )
	
	if ( !WaveExists( $guess ) || !WaveExists( $hold ) )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return NaN
	endif
	
	if ( NMKeidingPDFcheck() != 0 )
		return 0
	endif
	
	if ( !autoguess && !constraints )
		return 0
	endif
	
	String statsList = NM_PDFstats( wName, quiet = 1, make_MN_SD_Waves=0 )
	
	mn = str2num( StringByKey("mean", statsList, "=") )
	
	if ( numtype( mn ) != 0 )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return NaN
	endif
	
	stdvx = str2num( StringByKey("stdv", statsList, "=") )
	
	if ( numtype( stdvx ) != 0 )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return NaN
	endif
	
	xmin = str2num( StringByKey("xmin", statsList, "=") )
	xmax = str2num( StringByKey("xmax", statsList, "=") )
	xwidth = abs( xmax - xmin )
	
	phi = asin( xmin / mn ) * 180 / pi // degrees
	
	if ( autoguess )
	
		Wave FT_guess = $guess
		Wave FT_hold = $hold
	
		//if ( FT_hold[ 0 ] != 1 )
		//	FT_guess[ 0 ] = mn
		//endif
		
		//if ( FT_hold[ 1 ] != 1 )
		//	FT_guess[ 1 ] = stdvx
		//endif
		
		if ( FT_hold[ 2 ] != 1 )
			FT_guess[ 2 ] = phi
		endif
	
	endif
	
	if ( constraints )
	
		Wave FT_low = $low
		Wave FT_high = $high
	
		FT_low[ 0 ] = xmin
		FT_high[ 0 ] = xmax
		
		FT_low[ 1 ] = 0
		FT_high[ 1 ] = stdvx * 2
		
		FT_low[ 2 ] = 0 // degrees
		FT_high[ 2 ] = 90 // degrees
	
	endif
	
	return 0

End // NMKeidingChiInit

//****************************************************************//

Function NMKeidingChi( w, x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = KeidingChi(f,beta,phi,T)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = f
	//CurveFitDialog/ w[1] = beta
	//CurveFitDialog/ w[2] = phi
	//CurveFitDialog/ w[3] = T
	
	Variable x_max, zeta_, radians
	Variable phi = w[2]
	Variable T = w[3]
	//Variable x_min = x
	//Variable options = 2 // 2:	Gaussian Quadrature integration
	//Variable count = 0 // adaptive
	
	Variable mn = NMKeidingChiPDFMean( w[0], w[1] )
	Variable f = NMKeidingChiPDF( x, w[0], w[1] )
	
	if ( phi == 0 ) // Bach
		zeta_ = T + mn
		x_max = NumVarOrDefault( NMFitDF+"KeidingXmax", 100 ) // needs to be greater than x-max of data
	elseif ( phi == 90 ) // G = F
		return f
	else // Keiding
		radians = phi * pi / 180.0
		zeta_ = T + mn * cos(radians)
		x_max = x / sin(radians)
	endif
	
	Variable /G NMKeiding_Integrate_Xvalue = x
	
	//Variable i1D = integrate1D(NMKeidingChiIntegral, x_min, x_max, options, count, w)
	Variable i1D = integrate1D(NMKeidingChiIntegral, x, x_max, 2, 0, w)
	
	return ( T * f + x * i1D ) / zeta_
	
End // NMKeidingChi

//****************************************************************//

Function NMKeidingChiIntegral(w, xVOI)
	Wave w
	// w[0] = f
	// w[1] = beta
	// w[2] = phi (not used)
	// w[3] = T (not used)
	Variable xVOI
	
	NVAR Xvalue = NMKeiding_Integrate_Xvalue
	
	Variable xsd = sqrt(xVOI * xVOI - Xvalue * Xvalue)
	
	if (xsd == 0)
		xsd = 0.0000001 // avoid singularity
	endif

	return NMKeidingChiPDF( xVOI, w[0], w[1] ) / xsd
	
End // NMKeidingChiIntegral

//****************************************************************

Function NMKeidingChi3( w, x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = KeidingChi3(f,beta,phi,T,p1,p2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = f
	//CurveFitDialog/ w[1] = beta
	//CurveFitDialog/ w[2] = phi
	//CurveFitDialog/ w[3] = T
	//CurveFitDialog/ w[4] = p1
	//CurveFitDialog/ w[5] = p2
	
	Variable x_max, zeta_
	Variable phi = w[2]
	Variable radians = phi * pi / 180.0
	Variable T = w[3]
	
	//Variable x_min = x
	//Variable options = 2 // 2:	Gaussian Quadrature integration
	//Variable count = 0 // adaptive
	
	Variable beta1 = w[1]
	Variable beta2 = beta1 * 2 ^ (2.0/3.0)
	Variable beta3 = beta1 * 2 ^ (4.0/3.0)
	
	Variable mn1 = NMKeidingChiPDFMean( w[0], beta1 )
	Variable mn2 = NMKeidingChiPDFMean( w[0], beta2 )
	Variable mn3 = NMKeidingChiPDFMean( w[0], beta3 )
	
	Make /D/O/N=2 W_Coef2, W_Coef3
	
	W_Coef2[ 0 ] = w[ 0 ]
	W_Coef2[ 1 ] = beta2
	
	W_Coef3[ 0 ] = w[ 0 ]
	W_Coef3[ 1 ] = beta3
	
	Variable p3 = 1 - w[4] - w[5]
	
	Variable pp1 = w[4] / ( T + mn1 * cos(radians) )
	Variable pp2 = w[5] / ( T + mn2 * cos(radians) )
	Variable pp3 = p3 / ( T + mn3 * cos(radians) )
	Variable sumpp = pp1 + pp2 + pp3
	Variable q1 = pp1 / sumpp
	Variable q2 = pp2 / sumpp
	Variable q3 = pp3 / sumpp
	
	Variable qmn = q1 * mn1 + q2 * mn2 + q3 * mn3
	
	Variable f1 = NMKeidingChiPDF( x, w[0], beta1 )
	Variable f2 = NMKeidingChiPDF( x, w[0], beta2 )
	Variable f3 = NMKeidingChiPDF( x, w[0], beta3 )
	
	if ( phi == 0 ) // Bach
		zeta_ = T + qmn
		x_max = NumVarOrDefault( NMFitDF+"KeidingXmax", 100 ) // needs to be greater than x-max of data
	elseif ( phi == 0 ) // G = F
		return f1 + f2 + f3
	else // Keiding
		zeta_ = T + qmn * cos(radians)
		x_max = x / sin(radians)
	endif
	
	Variable /G NMKeiding_Integrate_Xvalue = x
	
	Variable i1D1 = integrate1D(NMKeidingChiIntegral, x, x_max, 2, 0, w)
	Variable i1D2 = integrate1D(NMKeidingChiIntegral, x, x_max, 2, 0, W_Coef2)
	Variable i1D3 = integrate1D(NMKeidingChiIntegral, x, x_max, 2, 0, W_Coef3)
	
	Variable g1 = T * f1 + x * i1D1
	Variable g2 = T * f2 + x * i1D2
	Variable g3 = T * f3 + x * i1D3
	
	return ( q1 * g1 + q2 * g2 + q3 * g3 ) / zeta_
	
End // NMKeidingChi3

//****************************************************************//

Function NMKeidingGammaInit()

	Variable icnt, x_offset, mn, stdvx, phi, xmin, xmax, xwidth
	
	Variable autoguess = NMFitVarGet( "KeidingGuessAuto" )
	Variable constraints = 0 // NMFitVarGet( "KeidingConstraints" )
	
	String wName = CurrentNMWaveName()
	String guess = NMFitWavePath( "guess" )
	String hold = NMFitWavePath( "hold" )
	String low = NMFitWavePath( "low" )
	String high = NMFitWavePath( "high" )
	
	if ( !WaveExists( $guess ) || !WaveExists( $hold ) )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return NaN
	endif
	
	if ( NMKeidingPDFcheck() != 0 )
		return 0
	endif
	
	if ( !autoguess && !constraints )
		return 0
	endif
	
	String statsList = NM_PDFstats( wName, quiet = 1, make_MN_SD_Waves=0 )
	
	mn = str2num( StringByKey("mean", statsList, "=") )
	
	if ( numtype( mn ) != 0 )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return NaN
	endif
	
	stdvx = str2num( StringByKey("stdv", statsList, "=") )
	
	if ( numtype( stdvx ) != 0 )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return NaN
	endif
	
	xmin = str2num( StringByKey("xmin", statsList, "=") )
	xmax = str2num( StringByKey("xmax", statsList, "=") )
	xwidth = abs( xmax - xmin )
	
	phi = asin( xmin / mn ) * 180 / pi // degrees
	
	if ( autoguess )
	
		Wave FT_guess = $guess
		Wave FT_hold = $hold
	
		x_offset = FT_guess[ 0 ]
		
		//if ( FT_hold[ 1 ] != 1 )
			//FT_guess[ 1 ] = ( ( mn - x_offset ) ^ 2 ) / ( stdvx ^ 2 )
		//endif
		
		//if ( FT_hold[ 2 ] != 1 )
			//FT_guess[ 2 ] = ( stdvx ^ 2 ) / ( mn - x_offset )
		//endif
		
		if ( FT_hold[ 3 ] != 1 )
			FT_guess[ 3 ] = phi
		endif
	
	endif
	
	if ( constraints )
	
		Wave FT_low = $low
		Wave FT_high = $high
	
		FT_low[ 0 ] = 0
		FT_high[ 0 ] = xmax
		
		FT_low[ 1 ] = 0
		FT_high[ 1 ] = 500
		
		FT_low[ 2 ] = 0
		FT_high[ 2 ] = 500
		
		FT_low[ 3 ] = 0 // degrees
		FT_high[ 3 ] = 90 // degrees
	
	endif
	
	return 0

End // NMKeidingGammaInit

//****************************************************************//

Function NMKeidingGamma( w, x ) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = KeidingGamma(x0,f,beta,phi,T)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = x0
	//CurveFitDialog/ w[1] = f
	//CurveFitDialog/ w[2] = beta
	//CurveFitDialog/ w[3] = phi
	//CurveFitDialog/ w[4] = T
	
	// see Igor StatsGammaPDF(x, µ, σ, γ )
	// w[0] = x0 = µ // location parameter
	// w[1] = f = γ // shape parameter
	// w[2] = beta = σ // scale parameter
	
	if ( x < w[0] )
		return 0
	endif
	
	Variable x_max, zeta_, radians
	Variable phi = w[3]
	Variable T = w[4]
	
	//Variable x_min = x
	//Variable options = 2 // 2:	Gaussian Quadrature integration
	//Variable count = 0 // adaptive
	
	Variable mn = w[0] + w[1] * w[2]
	Variable f = StatsGammaPDF( x, w[0], w[2], w[1] ) // NOTE ORDER: w[2], w[1] 
	
	if ( phi == 0 ) // Bach
		zeta_ = T + mn
		x_max = NumVarOrDefault( NMFitDF+"KeidingXmax", 100 ) // needs to be greater than x-max of data
	elseif ( phi == 90 ) // G = F
		return f
	else // Keiding
		radians = phi * pi / 180.0
		zeta_ = T + mn * cos(radians)
		x_max = x / sin(radians)
	endif
	
	Variable /G NMKeiding_Integrate_Xvalue = x
	
	//Variable i1D = integrate1D(NMKeidingGammaIntegral, x_min, x_max, options, count, w)
	Variable i1D = integrate1D(NMKeidingGammaIntegral, x, x_max, 2, 0, w)
	
	return ( T * f + x * i1D ) / zeta_
	
End // NMKeidingGamma

//****************************************************************//

Function NMKeidingGammaIntegral(w, xVOI)
	Wave w
	// w[0] = x0
	// w[1] = f
	// w[2] = beta
	// w[3] = phi (not used)
	// w[4] = T (not used)
	Variable xVOI
	
	NVAR xvalue = NMKeiding_Integrate_Xvalue
	
	Variable xsd = sqrt(xVOI * xVOI - xvalue * xvalue)
	
	if (xsd == 0)
		xsd = 0.0000001 // avoid singularity
	endif
	
	return StatsGammaPDF( xVOI, w[0], w[2], w[1] ) / xsd // note order: w[2] w[1] 
	
End // NMKeidingGammaIntegral

//****************************************************************//
//
//	Utility functions
//
//****************************************************************//

Function /S NMKeidingGaussMakeG( [ folderName, wNameG, T, phi, diam3D_mean, diam3D_stdv, diam_max, diam_step, diam_units, wNameF, stats, overwrite ] )
	String folderName
	String wNameG // output wave name for G(d)
	Variable T // section thickness
	Variable phi // cap-angle limit // degrees
	Variable diam3D_mean, diam3D_stdv // mean and stdv of Gaussian F(d)
	Variable diam_max, diam_step // max diameter and diameter increment of G(d) and F(d)
	String diam_units // dimension units, e.g. "mm"
	String wNameF // output wave name for F(d)
	Variable stats // compute PDF stats
	Variable overwrite
	
	Variable diam_npnts, diam_bgn = 0
	String alert
	
	if ( ParamIsDefault( folderName ) )
		folderName = CurrentNMFolder( 0 )
	endif
	
	if ( ParamIsDefault( wNameG ) )
		wNameG = "DEFAULT"
	endif
	
	if ( ParamIsDefault( wNameF ) )
		wNameF = ""
	endif
	
	if ( ParamIsDefault( diam3D_mean ) )
		diam3D_mean = 1
	endif
	
	if ( ParamIsDefault( diam_max ) )
		diam_max = 1.1 * ( diam3D_mean + 3 * diam3D_stdv )
	endif
	
	if ( ParamIsDefault( diam_step ) )
		diam_step = diam_max / 500
	endif
	
	if ( ParamIsDefault( diam_units ) )
		diam_units = ""
	endif
	
	if ( ( numtype( T ) > 0 ) || ( T < 0 ) )
		return NM2ErrorStr( 10, "T", num2str( T ) )
	endif
	
	if ( ( numtype( phi ) > 0 ) || ( phi < 0 ) || ( phi > 90 ) )
		return NM2ErrorStr( 10, "phi", num2str( phi ) )
	endif
	
	if ( ( numtype( diam3D_mean ) > 0 ) || ( diam3D_mean <= 0 ) )
		return NM2ErrorStr( 10, "diam3D_mean", num2str( diam3D_mean ) )
	endif
	
	if ( ( numtype( diam3D_stdv ) > 0 ) || ( diam3D_stdv < 0 ) )
		return NM2ErrorStr( 10, "diam3D_stdv", num2str( diam3D_stdv ) )
	endif
	
	if ( ( numtype( diam_max ) > 0 ) || ( diam_max <= 0 ) )
		return NM2ErrorStr( 10, "diam_max", num2str( diam_max ) )
	endif
	
	if ( ( numtype( diam_step ) > 0 ) || ( diam_step <= 0 ) )
		return NM2ErrorStr( 10, "diam_step", num2str( diam_step ) )
	endif
	
	diam_npnts = 1 + (diam_max - diam_bgn) / diam_step
	
	if ( ( numtype( diam_npnts ) > 0 ) || ( diam_npnts <= 0 ) )
		return NM2ErrorStr( 10, "diam_npnts", num2str( diam_npnts ) )
	endif
	
	NMFolderCheck( folderName )
	
	if ( StringMatch( wNameG, "DEFAULT" ) )
		if ( phi < 10 )
			wNameG = "G_T" + num2istr( T ) + "_P0" + num2istr( phi )
		else
			wNameG = "G_T" + num2istr( T ) + "_P" + num2istr( phi )
		endif
	endif
	
	if ( !overwrite && WaveExists( $wNameG ) )
		return NM2ErrorStr( 2, "wNameG", wNameG )
	endif
	
	if ( strlen( wNameF ) > 0 )
	
		if ( !overwrite && WaveExists( $wNameF ) )
			return NM2ErrorStr( 2, "wNameF", wNameF )
		endif
	
		Make /D/O/N=(diam_npnts) $wNameF
		Wave ftemp = $wNameF
		Setscale /P x 0, diam_step, ftemp
		ftemp = Gauss(x, diam3D_mean, diam3D_stdv)
		NM_PDFunits( wNameF, diam_units )
		
		if ( stats )
			NM_PDFstats( wNameF, make_MN_SD_Waves=1 )
		endif
		
	endif
	
	Make /D/O/N=(diam_npnts) $wNameG
	Wave gtemp = $wNameG
	Setscale /P x 0, diam_step, gtemp
	NM_PDFunits( wNameG, diam_units )
	
	if ( phi == 90 )
	
		gtemp = Gauss( x, diam3D_mean, diam3D_stdv ) // all caps are lost
	
	else
	
		Make /D/O/N=4 W_Coef
		W_Coef[0] = diam3D_mean
		W_Coef[1] = diam3D_stdv
		W_Coef[2] = phi
		W_Coef[3] = T
		
		gtemp = NMKeidingGauss(W_Coef, x)
	
	endif
	
	if ( stats )
		NM_PDFstats( wNameG, make_MN_SD_Waves=1 )
	endif
	
	KillVariables /Z NMKeiding_Integrate_Xvalue, W_Coef
	
	return wNameG

End // NMKeidingGaussMakeG

//****************************************************************//

Function NMKeidingGaussPhiCutoffEstimate( wName_W_Coef )
	String wName_W_Coef // wave name of fit W_Coef
	
	if ( !WaveExists( $wName_W_Coef ) || ( numpnts( $wName_W_Coef ) != 6 ) )
		return NaN
	endif
	
	Wave coef = $wName_W_Coef
	
	Variable diam3D_mean = coef[ 0 ]
	Variable diam3D_stdv = coef[ 1 ]
	Variable phi = coef[ 2 ]
	Variable num_diam = coef[ 4 ]
	
	Variable phi_cutoff = NMKeidingGaussPhiCutoff( num_diam, diam3D_mean, diam3D_stdv, "estimate", phi=phi )
	
	coef[ 5 ] = phi_cutoff
	
End // NMKeidingGaussPhiCutoffEstimate

//****************************************************************//

Function NMKeidingGaussPhiCutoff( num_diam, diam3D_mean, diam3D_stdv, diam3D_type [ phi ] ) // Rothman et al 2023
	Variable num_diam // # of diameter measurements
	Variable diam3D_mean, diam3D_stdv // Gaussian F(d) (true or estimates)
	String diam3D_type // "true" or "estimate"
	Variable phi // for comparison test
	
	Variable k1, k2, k3, k4 = 0, k5 = 0, k6 = 0
	Variable phicutoff, compare
	String ctxt
	
	if ( ( numtype( num_diam ) > 0 ) || ( num_diam <= 0 ) )
		return NaN
	endif
	
	if ( !ParamIsDefault( phi ) && ( numtype( phi ) == 0 ) && ( phi >= 0 ) && ( phi <= 90 ) )
		compare = 1
	endif
	
	strswitch( diam3D_type )
		case "true": // Equation 7
			k1 = 1.0430243
			k2 = -1.5337296
			k3 = -0.5168194
			k5 = -17.105866
			break
		case "estimate": // Equation 8
			k1 = 0.9866808
			k2 = -2.0708220
			k3 = 0.1243357
			k5 = -35.059480
			break
		default:
			Print "error: unkwown parameter type:", diam3D_type
			return NaN
	endswitch
	
	Variable CVD = diam3D_stdv / diam3D_mean
	Variable invN = 1 / SQRT(num_diam)
	Variable sin_phi_cutoff = k1 + k2 * CVD + k3 * invN + k4 * CVD^2 + k5 * CVD * invN + k6 * invN^2
	
	phicutoff = asin( sin_phi_cutoff ) * 180 / pi // degrees
	
	if ( compare )
	
		if ( phi < phicutoff )
			ctxt = "ϕ is determinable: ϕ < ϕ-cutoff: " + num2str( phi ) + "° < " + num2str( phicutoff ) + "°"
		else
			ctxt = "WARNING: ϕ is likely to be indeterminable: ϕ > ϕ-cutoff: " + num2str( phi ) + "° > " + num2str( phicutoff ) + "°"
		endif
		
		NMHistory( ctxt )
	
	endif
	
	return phicutoff
	
End // NMKeidingGaussPhiCutoff

//****************************************************************//

Function NMKeidingChiPDF( x, f, beta_ ) // Keiding et al 1972 Eq. 3.1
	Variable x, f, beta_
	
	Variable hf = 0.5 * f
	Variable g = 2 ^ ( hf - 1 ) * gamma( hf ) * beta_^hf
	
	return x ^ ( f - 1 ) * exp( -x * x / ( 2 * beta_ ) ) / g
	
End // NMKeidingChiPDF

//****************************************************************//

Function NMKeidingChiPDFMean( f, beta_ ) // Keiding et al 1972 Eq. 3.2
	Variable f, beta_
	
	return sqrt( 2 * beta_ ) * gamma( 0.5 * ( f + 1 ) ) / gamma( 0.5 * f )
	
End // NMKeidingChiPDFMean

//****************************************************************//

Function NMKeidingChiPDFStdv( f, beta_ ) // Keiding et al 1972 Eq. 3.2
	Variable f, beta_
	
	Variable g = gamma( 0.5 * ( f + 1 ) ) / gamma( 0.5 * f )
	
	return sqrt( beta_ * ( f - 2 * g ^ 2 ) ) // sqrt( variance )
	
End // NMKeidingChiPDFStdv

//****************************************************************//

Function NM_Weibel_Kv( sectionT, diam3D_mean, diam3D_stdv, phi_degrees )
	Variable sectionT // section thickness
	Variable diam3D_mean, diam3D_stdv // mean and stdv of 3D diameters
	Variable phi_degrees // Keiding cap-angle limit
	
	// Weibel ER, Paumgartner D.
	// Integrated stereological and biochemical studies on hepatocytic membranes.
	// II. Correction of section thickness effect on volume and surface density estimates.
	// J Cell Biol. 1978 May;77(2):584-97. doi: 10.1083/jcb.77.2.584. PMID: 649660; PMCID: PMC2110059.
	// Equation 37
	
	double g = sectionT / diam3D_mean
	double chi = 1 - cos( phi_degrees * pi / 180 ) // Rothman et al 2023 / S1_file.PDF / Eq A2.2c
	double dm2 = diam3D_mean * diam3D_mean
	double dm3 = diam3D_mean * diam3D_mean * diam3D_mean
	double ds2 = diam3D_stdv * diam3D_stdv
	double m2 = ( dm2 + ds2 ) / dm2
	double m3 = diam3D_mean * ( dm2 + 3 * ds2 ) / dm3
	double kv = 2 * m3 / ( 2 * m3 + 3 * g * m2 - 3 * chi^2 + chi^3)
	return kv

End // NM_Weibel_Kv

//****************************************************************//

Macro NM_Convert_Density_To_VF( density3D, diam3D_mean, diam3D_stdv )
	Variable density3D // e.g. #/um^3
	Variable diam3D_mean, diam3D_stdv // e.g. um
	
	Variable VF = NM_Density2VF( density3D, diam3D_mean, diam3D_stdv )
	
	NMHistory( "Volume Fraction = " + num2str( VF ) )
	
End // NM_Convert_Density_To_VF

//****************************************************************//

Function NM_Density2VF( density3D, diam3D_mean, diam3D_stdv )
	Variable density3D // e.g. #/um^3
	Variable diam3D_mean, diam3D_stdv // e.g. um // Gauss MN ± SD
	
	Variable volume_per_particle, volume_fraction, pnt

	Variable xsteps = 500
	Variable stdv_above_mean = 12
	Variable diam_max = diam3D_mean + diam3D_stdv * stdv_above_mean
	Variable dx = diam_max / xsteps
	Variable npnts = diam_max / dx
	
	if ( numtype( density3D * diam3D_mean * diam3D_stdv ) > 0 )
		return NaN
	endif
	
	if ( density3D == 0 )
		return 0
	endif
	
	if ( ( density3D < 0 ) || ( diam3D_mean <= 0 ) )
		return NaN
	endif
	
	if ( diam3D_stdv <= 0 )
		volume_per_particle = (4/3) * PI * (0.5 * diam3D_mean)^3
		return ( density3D * volume_per_particle )
	endif
	
	//Print "3D density =", density3D
	//Print "D =", diam_mean, "±", diam_stdv
	
	//volume_per_particle = (4/3) * PI * (0.5 * diam_mean)^3
	//volume_fraction = volume_per_particle * density3D // approximate
	
	Make /O/N=(npnts) xTemp_Fd, xTemp_Volume
	Setscale /P x 0, dx, xTemp_Fd, xTemp_Volume
	
	xTemp_Fd = Gauss( x, diam3D_mean, diam3D_stdv)
	
	xTemp_Volume = (4/3) * PI * (0.5 * x)^3 // e.g. um3
	
	xTemp_Volume *= xTemp_Fd // e.g. um3 * um-1 = um2
	
	Integrate xTemp_Volume // e.g. um3
	
	WaveStats /Q xTemp_Volume
	
	volume_per_particle = V_max
	volume_fraction = volume_per_particle * density3D
	
	//Print (4/3) * PI * (0.5 * diam_mean)^3
	//Print "CORRECT: volume computed from Gaussian distribution =", volume_per_particle, "um3"
	//Print "CORRECT: volume fraction =", volume_fraction
	
	KillWaves /Z xTemp_Fd, xTemp_Volume
	
	return volume_fraction
	
End // NM_Density2VF

//****************************************************************//

Macro NM_Convert_VF_To_Density( volume_fraction, diam3D_mean, diam3D_stdv )
	Variable volume_fraction // e.g. 0.14
	Variable diam3D_mean, diam3D_stdv // e.g. um
	
	Variable d = NM_VF2Density( volume_fraction, diam3D_mean, diam3D_stdv )
	
	NMHistory( "3D density = " + num2str( d ) )
	
End // NM_Convert_VF_To_Density

//****************************************************************//

Function NM_VF2Density( volume_fraction, diam3D_mean, diam3D_stdv )
	Variable volume_fraction // e.g. 0.14
	Variable diam3D_mean, diam3D_stdv // e.g. um // Gauss MN ± SD
	
	Variable volume_per_particle, density3D, pnt

	Variable xsteps = 500
	Variable stdv_above_mean = 12
	Variable diam_max = diam3D_mean + diam3D_stdv * stdv_above_mean
	Variable dx = diam_max / xsteps
	Variable npnts = diam_max / dx
	
	if ( numtype( volume_fraction * diam3D_mean * diam3D_stdv ) > 0 )
		return NaN
	endif
	
	if ( volume_fraction == 0 )
		return 0
	endif
	
	if ( ( volume_fraction < 0 ) || ( volume_fraction > 1 ) )
		return NaN
	endif
	
	if ( diam3D_mean <= 0 )
		return NaN
	endif
	
	if ( diam3D_stdv <= 0 )
		volume_per_particle = (4/3) * PI * (0.5 * diam3D_mean)^3
		return ( volume_fraction / volume_per_particle )
	endif
	
	//Print "VF =", volume_fraction
	//Print "D =", diam_mean, "±", diam_stdv
	
	//volume_per_particle = (4/3) * PI * (0.5 * diam_mean)^3
	//density3D = volume_fraction / volume_per_particle // approximate
	
	Make /O/N=(npnts) xTemp_Fd, xTemp_Volume
	Setscale /P x 0, dx, xTemp_Fd, xTemp_Volume
	
	xTemp_Fd = Gauss( x, diam3D_mean, diam3D_stdv)
	
	xTemp_Volume = (4/3) * PI * (0.5 * x)^3 // e.g. um3
	
	xTemp_Volume *= xTemp_Fd // e.g. um3 * um-1 = um2
	
	Integrate xTemp_Volume // e.g. um3
	
	WaveStats /Q xTemp_Volume
	
	volume_per_particle = V_max
	//volume_fraction = volume_per_particle * density3D
	density3D = volume_fraction / volume_per_particle
	
	//print (4/3) * PI * (0.5 * diam_mean)^3
	//Print "CORRECT: volume computed from Gaussian distribution =", volume_per_particle, "um3"
	//Print "CORRECT: volume fraction =", volume_fraction
	
	KillWaves /Z xTemp_Fd, xTemp_Volume
	
	return density3D
	
End // NM_VF2Density

//****************************************************************//

Function NMKeidingPDFcheck()
	
	Variable avalue
	
	String wName = CurrentNMWaveName()
	
	if ( !WaveExists( $wName ) )
		SetNMVar( NMFitDF + "Cancel", 1 )
		return -1
	endif
	
	Duplicate /O $wName XTEMP
	
	Integrate XTEMP
	
	WaveStats /Q XTEMP
	
	if ( round( V_max * 10 ) != 10 )
		
		avalue = NMDoAlert( "Warning: PDF wave " + NMQuotes( wName ) + " does not integrate to 1. Do you want to continue?", title="NM Check PDF", alertType = 1 )
		
		if ( avalue != 1 )
			SetNMVar( NMFitDF + "Cancel", 1 )
			return -1
		endif
		
	endif
	
	return 0 // OK
	
End // NMKeidingPDFcheck

//****************************************************************//

Function /S NM_PDFstats( wName [ precision, make_MN_SD_Waves, quiet ]) // mean, stdv, min, max, area
	String wName // PDF wave name
	Variable precision
	Variable make_MN_SD_Waves
	Variable quiet
	
	Variable icnt, dx, p_area = 0, mn = 0, sd = 0, xmin = inf, xmax = -inf
	String wName2, mnstr, sdstr, xminstr, xmaxstr, areastr
	
	if ( ParamIsDefault( precision ) )
		precision = 12
	endif
	
	if (!WaveExists($wName))
		return ""
	endif
	
	Wave wtemp = $wName
	
	dx = deltax(wtemp)
	p_area = sum( wtemp ) * dx
	
	for (icnt = 0 ; icnt < numpnts(wtemp) ; icnt += 1)
		if ( wtemp[icnt] > 0 )
			xmin = pnt2x(wtemp, icnt)
			break
		endif
	endfor
	
	for (icnt = numpnts(wtemp) - 1 ; icnt >= 0 ; icnt -= 1)
		if ( wtemp[icnt] > 0 )
			xmax = pnt2x(wtemp, icnt)
			break
		endif
	endfor
	
	for (icnt = 0 ; icnt < numpnts(wtemp) ; icnt += 1)
		mn += pnt2x(wtemp, icnt) * wtemp[icnt] * dx // x * PDF(x) * dx
	endfor
	
	for (icnt = 0 ; icnt < numpnts(wtemp) ; icnt += 1)
		sd += (pnt2x(wtemp, icnt) - mn)^2 * wtemp[icnt] * dx // (x - mn)^2 * PDF(x) * dx
	endfor
	
	sd = sqrt(sd)
	
	if ( make_MN_SD_Waves )
	
		wName2 = "MN_" + wName
		Make /D/O/N=1 $wName2 = mn
		
		wName2 = "SD_" + wName
		Make /D/O/N=1 $wName2 = sd
	
	endif
	
	sprintf mnstr, "%." + num2istr( precision) + "f", mn
	sprintf sdstr, "%." + num2istr( precision) + "f", sd
	sprintf xminstr, "%." + num2istr( precision) + "f", xmin
	sprintf xmaxstr, "%." + num2istr( precision) + "f", xmax
	sprintf areastr, "%." + num2istr( precision) + "f", p_area
	
	if ( !quiet )
		NMHistory( wName + " stats: μ ± σ = " + mnstr + " ± " + sdstr + ", area = " + areastr )
	endif
	
	return "mean=" + mnstr + ";stdv=" + sdstr + ";xmin=" + xminstr + ";xmax=" + xmaxstr + ";" + ";area=" + areastr + ";"

End // NM_PDFstats

//**************************************************************** //
//
//	Demo functions based on Rothman et al 2023
//
//**************************************************************** //

Function /S NMKeidingGaussMakeGCall( [ diam3D_mean, diam3D_stdv, TList, phiList ] ) // Rothman et al 2023 Fig 3
	Variable diam3D_mean, diam3D_stdv // mean and stdv of Gaussian F(d)
	String TList // section thickness list, e.g. "0;1;"
	String phiList // phi list, e.g. "00;10;20;30;40;50;60;70;80;"

	Variable pcnt, tcnt, phi, Tvalue
	String wNameG, wList = ""
	String gName, gList1, gList2 = ""
	
	Variable diam_max = 1.5
	Variable diam_pnts = 500
	Variable diam_step = diam_max / diam_pnts
	
	Variable overwrite = 1
	
	String folderName = "KeidingAnalytical"
	String wNameF = "F_Gauss"
	String wavePrefix = "G_T"
	
	if ( ParamIsDefault( diam3D_mean ) )
		diam3D_mean = 1
	endif
	
	if ( ParamIsDefault( diam3D_stdv ) )
		diam3D_stdv = 4 / 46 // vesicles
	endif
	
	if ( ParamIsDefault( TList ) )
		TList = "0;1;"
	endif
	
	if ( ParamIsDefault( phiList ) )
		phiList = "00;10;20;30;40;50;60;70;80;90;"
	endif
	
	NMFolderCheck( folderName )
	
	if ( overwrite )
		NMKillWaves( WaveList( wavePrefix + "*", ";", "" ) )
	endif
	
	for ( pcnt = 0 ; pcnt < ItemsInList( phiList ) ; pcnt += 1 )
		
		phi = str2num( StringFromList( pcnt, phiList ) )
		
		for ( tcnt = 0 ; tcnt < ItemsInList( TList ) ; tcnt += 1 )
		
			Tvalue = str2num( StringFromList( tcnt, TList ) )
			
			wNameG = NMKeidingGaussMakeG( T=tvalue, phi=phi, diam3D_mean=diam3D_mean, diam3D_stdv=diam3D_stdv, diam_max=diam_max, diam_step=diam_step, wNameF=wNameF, overwrite=overwrite )
			wNameF = "" // stop computing after first pass
			
			if ( strlen( wNameG ) > 0 )
				wList += wNameG + ";"
			endif
			
		endfor
		
	endfor
	
	for ( tcnt = 0 ; tcnt < ItemsInList( TList ) ; tcnt += 1 )
		NMSet( wavePrefix="G_T" + StringFromList( tcnt, TList ) )
		NMSet( waveNum=0 )
		gList1 = NMMainGraph( color="rainbow" )
		gList2 += StringFromList( 0, gList1 ) + ";"
	endfor
	
	for ( tcnt = 0 ; tcnt < ItemsInList( gList2 ) ; tcnt += 1 )
		gName = StringFromList( tcnt, gList2 )
		DoWindow /F $gName
	endfor
	
	return wList
	
End // NMKeidingGaussMakeGCall

//**************************************************************** //
//
//	The Corpuscle Problem: A Mathematical Study of a Biometric Problem
//	Wicksell 1925
//	Biometrika , Jun., 1925, Vol. 17, No. 1/2 (Jun., 1925), pp. 84-99
//	Example 4
//
//**************************************************************** //

Function NMKeiding_Wicksell_Check( [ overwrite ] ) // Rothman et al Fig S3 in S1_File.pdf
	Variable overwrite
	
	Variable new
	String wName
	
	Variable xstart = 0
	
	NMFolderCheck( WicksellFolder )
	
	wName = "F_Wicksell"
	
	if ( overwrite || !WaveExists( $wName ) )
		NMHistoFreqList2Wave( Wicksell_F, wName, xstart, Wicksell_G_BinWidth, probability=1, overwrite=overwrite )
		NMSet( wavePrefix="F_" )
		NMChanXLabelSetAll( "Spleen follicle 3D diameter x" + num2str( Wicksell_Magnification ) + " (" + Wicksell_G_Units + ")" )
		NMChanLabelSet( 0, 2, "y", PDF_YLabel( Wicksell_G_Units ) )
		NM_PDFstats( wName, make_MN_SD_Waves=1 ) // mean matches Wicksell
	endif
	
	wName = "G_Wicksell"
	
	if ( overwrite || !WaveExists( $wName ) )
		NMHistoFreqList2Wave( Wicksell_G, wName, xstart, Wicksell_G_BinWidth, probability=1, overwrite=overwrite )
		new = 1
	endif
	
	NMSet( wavePrefix="G_" )

	if ( new )
		NMChanXLabelSetAll( "Spleen follicle 2D diameter x" + num2str( Wicksell_Magnification ) + " (" + Wicksell_G_Units + ")" )
		NMChanLabelSet( 0, 2, "y", PDF_YLabel( Wicksell_G_Units ) )
	endif
	
	DoUpdate /W=$ChanGraphName(0)
	
	return 0
	
End // NMKeiding_Wicksell_Check

//**************************************************************** //

Function NMKeiding_Wicksell_Fit( [ graph ] )
	Variable graph
	
	Variable fit_f, fit_b, fit_mn, fit_sd, pnts, icnt, error, phi_cutoff
	String fName, fName2
	
	NMKeiding_Wicksell_Check()
	
	Variable avalue = NMDoAlert( "Compute fit to Wicksell's spleen-follicle G(d)?", title="Keiding-model Fit Demo", alertType = 1 )
	
	if ( avalue != 1 )
		return 0
	endif
	
	NMFitKeidingInit( fxn="NMKeidingChi" )
	
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_coef = $NMFitWavePath( "coef" )
	
	FT_guess[ 0 ] = 5 // f // // changed by NMKeidingGaussGuess
	FT_guess[ 1 ] = 9 // beta // mm^2
	FT_guess[ 2 ] = 15 // phi // degrees
	FT_guess[ 3 ] = Wicksell_T * Wicksell_Magnification // T // mm // scale T to match magnfication of nuclei
	
	error = NMFitWave()
	
	if ( error > 0 )
		NMHistory( "fit error: NMKeiding_Wicksell_Fit" )
		return error
	endif
	
	NMFitSaveCurrent()
	
	fit_f = FT_coef[ 0 ]
	fit_b = FT_coef[ 1 ]
	fit_mn = NMKeidingChiPDFMean( fit_f , fit_b )
	fit_sd = NMKeidingChiPDFStdv( fit_f , fit_b )
	
	Print "fit 3D diameter MN ± SD =", fit_mn, "±", fit_sd, "mm"
	Print "unscaled 3D diameter MN ± SD =", ( fit_mn / Wicksell_Magnification ), "±", ( fit_sd / Wicksell_Magnification ), "mm"
	
	fName = "Fit_G_Wicksell"
	fName2 = "F_" + fName
	
	Make /D/O/N=1 $"MN_" + fName2 = fit_mn
	Make /D/O/N=1 $"SD_" + fName2 = fit_sd
	
	if ( WaveExists( $fName ) )
		Duplicate /O $fName $fName2
		Wave ftemp = $fName2
		ftemp = NMKeidingChiPDF( x, fit_f , fit_b )
	endif
	
	if ( !graph )
		return 0
	endif
	
	NMKeiding_Wicksell_Fit_Graph()
	
	return 0
	
End // NMKeiding_Wicksell_Fit

//****************************************************************//

Function /S NMKeiding_Wicksell_Fit_Graph()

	String txt, txt2
	
	Variable overwriteMode = 1
	Variable currentChan = CurrentNMChannel()
	
	String fxn = NMFitStrGet( "FxnShort" )
	String gPrefix = "FT_" + CurrentNMFolderPrefix() + "WicksellG_" + fxn
	String gName = NextGraphName( gPrefix, currentChan, overwriteMode )
	String gTitle = NMFolderListName( "" ) + " : Wicksell G(d) : " + fxn + " Fit"
	
	NMFolderCheck( WicksellFolder )
	
	if ( !WaveExists( $"F_Wicksell" ) || !WaveExists( $"G_Wicksell" ) )
		return ""
	endif
	
	Wave F_Wicksell, G_Wicksell
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=(159,219,849,607) F_Wicksell,G_Wicksell as gTitle
	
	ModifyGraph mode(G_Wicksell)=3,mode(F_Wicksell)=3
	ModifyGraph marker(G_Wicksell)=19,marker(F_Wicksell)=19
	ModifyGraph rgb(G_Wicksell)=(19675,39321,1),rgb(F_Wicksell)=(0,0,0)
	ModifyGraph msize(G_Wicksell)=3.5,msize(F_Wicksell)=3.5
	ModifyGraph mrkThick(G_Wicksell)=1.25,mrkThick(F_Wicksell)=1.25
	
	if ( WaveExists( $"MN_F_Wicksell" ) && WaveExists( $"SD_F_Wicksell" ) )
		Wave MN_F_Wicksell, SD_F_Wicksell
		Make /O/N=1 Y0 = 0
		AppendToGraph Y0 vs MN_F_Wicksell
		ErrorBars Y0 X,wave=(SD_F_Wicksell,SD_F_Wicksell)
		ModifyGraph mode(Y0)=3, marker(Y0)=8, msize(Y0)=2.5, mrkThick(Y0)=1.25
		ModifyGraph rgb(Y0)=(0,0,0)
		ModifyGraph opaque(Y0)=1
		ModifyGraph offset(Y0)={0,0.030}
		txt2 = " (\\s(Y0))"
	else
		txt2 = ""
	endif
	
	txt = "\\Z10\r\\s(F_Wicksell) F(d) Wicksell" + txt2 + "\r"
	txt += "\\sa+12\\s(G_Wicksell) G(d) Wicksell\r"
	
	if ( WaveExists( $"Fit_G_Wicksell" ) )
		Wave Fit_G_Wicksell
		AppendToGraph Fit_G_Wicksell
		ModifyGraph lSize(Fit_G_Wicksell)=1.25
		ModifyGraph rgb(Fit_G_Wicksell)=(52428,1,1)
		txt += "\\sa+12\\s(Fit_G_Wicksell) Fit to G(d) (K-Chi)\r"
	endif
	
	if ( WaveExists( $"F_Fit_G_Wicksell" ) )
	
		Wave F_Fit_G_Wicksell
		AppendToGraph F_Fit_G_Wicksell
		ModifyGraph lSize(F_Fit_G_Wicksell)=1.25
		ModifyGraph lStyle(F_Fit_G_Wicksell)=3
		ModifyGraph rgb(F_Fit_G_Wicksell)=(52428,1,1)
		
		if ( WaveExists( $"MN_F_Fit_G_Wicksell" ) && WaveExists( $"SD_F_Fit_G_Wicksell" ) )
			Wave MN_F_Fit_G_Wicksell, SD_F_Fit_G_Wicksell
			Make /O/N=1 Y1 = 0
			AppendToGraph Y1 vs MN_F_Fit_G_Wicksell
			ModifyGraph mode(Y1)=3, marker(Y1)=8, msize(Y1)=2.5, mrkThick(Y1)=1.25
			ModifyGraph rgb(Y1)=(52428,1,1)
			ModifyGraph opaque(Y1)=1
			ModifyGraph offset(Y1)={0,0.015}
			ErrorBars Y1 X,wave=(SD_F_Fit_G_Wicksell,SD_F_Fit_G_Wicksell)
			txt2 = " (\\s(Y1))"
		else
			txt2 = ""
		endif
		
		txt += "\\sa+12\\s(F_Fit_G_Wicksell) F(d) from fit" + txt2
		
	endif
	
	ModifyGraph margin(left)=44,margin(bottom)=38,margin(top)=25,margin(right)=25
	ModifyGraph fSize=10
	ModifyGraph standoff=0
	ModifyGraph axThick=1.25
	ModifyGraph axisOnTop=1
	ModifyGraph manTick(left)={0,0.1,0,1},manMinor(left)={4,50}
	ModifyGraph manTick(bottom)={0,2,0,0},manMinor(bottom)={1,50}
	
	Label left "Probability density (mm\\S-1\\M)"
	Label bottom "Follicle diameter x" + num2istr( Wicksell_Magnification ) + " (mm)"
	SetAxis left*,0.2
	SetAxis bottom 0,16
	
	Legend/C/N=text0/J/F=0/M txt
	
	NMWinCascade( gName )
	
	return gName
	
End // NMKeiding_Wicksell_Fit_Graph

//**************************************************************** //
//
//	Keiding N, Jensen ST. 
//	Maximum likelihood estimation of the size distribution of liver cell nuclei from the observed distribution in a plane section
//	Biometrics. 1972 Sep;28(3):813-29
//	PMID: 5073254.
//	Table 1
//
//****************************************************************//

Function NMKeiding_Check( [ overwrite, computeOriginalFits ] ) // Rothman et al Fig S2 in S1_File.pdf
	Variable overwrite
	Variable computeOriginalFits
	
	Variable new, icnt
	String add_bins = ""
	
	Variable dx = Keiding_G_BinWidth * 2 / Keiding_Magnification
	Variable add_pnts = Keiding_G_BinStart / Keiding_G_BinWidth // 24 bins // missing bins at start of histograms
	
	Variable xstart = 0
	
	NMFolderCheck( KeidingFolder )
	
	if ( overwrite || !WaveExists( $"G_0_H0601" ) )
	
		for ( icnt = 0 ; icnt < add_pnts ; icnt += 1 )
			add_bins += "0;"
		endfor
		
		NMHistoFreqList2Wave( add_bins + Keiding_G_H0601, "G_0_H0601", xstart, dx, probability=1, overwrite=overwrite )
		NMHistoFreqList2Wave( add_bins + Keiding_G_H2003, "G_1_H2003", xstart, dx, probability=1, overwrite=overwrite )
		NMHistoFreqList2Wave( add_bins + Keiding_G_H1037, "G_2_H1037", xstart, dx, probability=1, overwrite=overwrite )
		
		new = 1
		
	endif
	
	NMSet( wavePrefix="G_" )

	if ( new )
		NMChanXLabelSetAll( "Liver cell nucleus 2D diameter (" + Keiding_G_Units + ")" )
		NMChanLabelSet( 0, 2, "y", PDF_YLabel( Keiding_G_Units ) )
	endif
	
	if ( computeOriginalFits )
		NMKeiding_Table2_Fits_All()
	endif
	
	DoUpdate /W=$ChanGraphName(0)
	
	return 0
	
End // NMKeiding_Check

//****************************************************************

Function NMKeiding_Table2_Fits_All() // fit values from Keiding Table 2

	Variable f, b, phi, p1, p2
	String wName
	
	Variable b_scale = 2 * 1000 / Keiding_Magnification // convert radius to diameter and mm to um and remove magnification
	
	NMFolderCheck( KeidingFolder )
	
	wName = "G_0_H0601"
	f = 2 * 52 // degrees freedom
	b = 0.987 / 2.0 // beta (mm^2)
	b *= b_scale^2 // um^2
	phi = 72.5 // degrees
	p1 = 0.889
	p2 = 0.109
	
	NMKeiding_Table2_Fits_( wName, f, b, phi, p1, p2, Keiding_T, diam_units=Keiding_G_Units )
	
	wName = "G_1_H2003"
	f = 2 * 104 // degrees freedom
	b = 0.523 / 2.0 // beta (mm^2)
	b *= b_scale^2 // um^2
	phi = 85 // degrees
	p1 = 0.864
	p2 = 0.122
	
	NMKeiding_Table2_Fits_( wName, f, b, phi, p1, p2, Keiding_T, diam_units=Keiding_G_Units )
	
	wName = "G_2_H1037"
	f = 2 * 35 // degrees freedom
	b = 1.910 / 2.0 // beta (mm^2)
	b *= b_scale^2 // um^2
	phi = 70 // degrees
	p1 = 0.887
	p2 = 0.100
	
	NMKeiding_Table2_Fits_( wName, f, b, phi, p1, p2, Keiding_T, diam_units=Keiding_G_Units )

End // NMKeiding_Table2_Fits_

//****************************************************************

Function NMKeiding_Table2_Fits_( wName, f, b, phi, p1, p2, T [ diam_max, diam_pnts, diam_units ] )
	String wName
	Variable f, b, phi, p1, p2, T
	Variable diam_max, diam_pnts
	String diam_units
	
	Variable diam_dx, chisqr, computeChiSqr = 1
	Variable ft_mn, ft_sd
	String cName, fName, wavePrefix = "KFit_"
	
	if ( ParamIsDefault( diam_units ) )
		diam_units = "μm"
	endif
	
	if ( !WaveExists( $wName ) )
		return -1
	endif
	
	Wave gtemp = $wName // G(d)
	
	if ( ParamIsDefault( diam_max ) )
		diam_max = 12
	endif
	
	if ( ParamIsDefault( diam_pnts ) )
		diam_pnts = 500
	endif 
	
	diam_dx = diam_max / diam_pnts
	
	Duplicate /O gtemp Temp_ChiSqr
	
	// Keiding F-chi fit
	
	cName = "W_Coef_" + wName + "_Chi3"
	Make /D/O/N=6 $cName
	Wave W_Coef = $cName
	
	W_Coef[ 0 ] = f
	W_Coef[ 1 ] = b // um^2
	W_Coef[ 2 ] = phi
	W_Coef[ 3 ] = T
	W_Coef[ 4 ] = p1
	W_Coef[ 5 ] = p2
	
	fName = wavePrefix + wName + "_Chi3"
	Make /D/O/N=( diam_pnts ) $fName
	Wave wtemp = $fName
	Setscale /P x 0, diam_dx, wtemp
	wtemp = NMKeidingChi3( W_Coef, x )
	NM_PDFunits( fName, diam_units )
	
	ft_mn = NMKeidingChiPDFMean( f, b )
	ft_sd = NMKeidingChiPDFStdv( f, b )
	
	Make /D/O/N=1 $"MN_" + fName = ft_mn
	Make /D/O/N=1 $"SD_" + fName = ft_sd
	
	if ( computeChiSqr )
		Temp_ChiSqr = NMKeidingChi3( W_Coef, x )
		Temp_ChiSqr = ( Temp_ChiSqr - gtemp )^2
		chisqr = sum( Temp_ChiSqr )
		Print wName + " F-Chi chi-square =", chisqr
	endif
	
	// convert fit to Keiding F-Gauss
	
	cName = "W_Coef_" + wName + "_Gauss3"
	Make /D/O/N=6 $cName
	Wave W_Coef = $cName
	
	W_Coef[ 0 ] = ft_mn
	W_Coef[ 1 ] = ft_sd
	W_Coef[ 2 ] = phi
	W_Coef[ 3 ] = T
	W_Coef[ 4 ] = p1
	W_Coef[ 5 ] = p2
	
	fName = wavePrefix + wName + "_Gauss3"
	Make /D/O/N=( diam_pnts ) $fName
	Wave wtemp = $fName
	Setscale /P x 0, diam_dx, wtemp
	wtemp = NMKeidingGauss3( W_Coef, x )
	NM_PDFunits( fName, diam_units )
	
	if ( computeChiSqr )
		Temp_ChiSqr = NMKeidingGauss3( W_Coef, x )
		Temp_ChiSqr = ( Temp_ChiSqr - gtemp )^2
		chisqr = sum( Temp_ChiSqr )
		Print wName + " F-Gauss chi-square =", chisqr
	endif
	
	KillWaves /Z Temp_ChiSqr, W_Coef2, W_Coef3

End // NMKeiding_Table2_Fits_2

//****************************************************************//

Function NMKeiding_Fit_All( [ computeOriginalFits, graph ] ) // LSE Keiding F-Gauss
	Variable computeOriginalFits
	Variable graph

	NMKeiding_Check( computeOriginalFits=computeOriginalFits )
	
	Variable avalue = NMDoAlert( "Compute fit to Keiding's 1972 G(d)?", title="Keiding-model Fit Demo", alertType = 1 )
	
	if ( avalue != 1 )
		return 0
	endif
	
	if ( NMKeiding_Fit( "G_0_H0601", num_diam=Keiding_N ) > 0 )
		return -1
	endif
	
	if ( NMKeiding_Fit( "G_1_H2003", num_diam=Keiding_N ) > 0 )
		return -1
	endif
	
	if ( NMKeiding_Fit( "G_2_H1037", num_diam=Keiding_N ) > 0 )
		return -1
	endif
	
	if ( graph )
		return NMKeiding_Graph_All()
	endif

	return 0

End // NMKeiding_Fit_All

//****************************************************************//

Function NMKeiding_Fit( wName [ fit_pnts, num_diam ] )
	String wName
	Variable fit_pnts
	Variable num_diam // for phi-cutoff test
	
	String cName, sName, fName
	
	Variable /G V_FitQuitReason = 0
	
	String statsList = NM_PDFstats( wName, quiet = 1, make_MN_SD_Waves=0 )
	Variable diam_mn = str2num( StringByKey("mean", statsList, "=") )
	Variable diam_sd = str2num( StringByKey("stdv", statsList, "=") )
	Variable xmin = str2num( StringByKey("xmin", statsList, "=") )
	Variable phi = asin( xmin / diam_mn ) * 180 / pi
	
	if ( numtype( diam_mn * diam_sd * phi ) != 0 )
		return -1
	endif
	
	if ( ParamIsDefault( fit_pnts ) )
		fit_pnts = 500
	endif
	
	Make /D/O/N=6 W_Coef
	Wave W_Coef
	
	W_Coef[ 0 ] = diam_mn
	W_Coef[ 1 ] = diam_sd
	W_Coef[ 2 ] = phi
	W_Coef[ 3 ] = Keiding_T
	W_Coef[ 4 ] = 0.9
	W_Coef[ 5 ] = 0.1
	
	FuncFit /H="000100"/L=(fit_pnts)/N=2/NTHR=0/ODR=0 NMKeidingGauss3, kwCWave=W_Coef, $wName /D
	
	fName = "Fit_" + wName // Igor's name for fit wave
	
	if ( WaveExists( $fName ) )
		Duplicate /O $fName $fName + "_LSE"
		KillWaves /Z $fName
		Make /D/O/N=1 $"MN_" + fName + "_LSE" = W_Coef[ 0 ]
		Make /D/O/N=1 $"SD_" + fName + "_LSE" = W_Coef[ 1 ]
	endif
	
	cName = "W_Coef_" + wName + "_LSE"
	Duplicate /O W_Coef $cName
	
	if ( WaveExists( $"W_Sigma" ) )
		Wave W_Sigma
		sName = "W_Sigma_" + wName + "_LSE"
		Duplicate /O W_Sigma $sName
	endif
	
	if ( num_diam > 0 )
		NMKeidingGaussPhiCutoff( num_diam, W_Coef[ 0 ], W_Coef[ 1 ], "estimate", phi=W_Coef[ 2 ] )
	endif
	
	KillWaves /Z W_Coef, W_Coef2, W_Coef3, W_Sigma // NMKeidingGauss3 creates W_Coef2, W_Coef3
	
	return V_FitQuitReason
	
End // NMKeiding_Fit

//****************************************************************//

Function NMKeiding_Graph_All()

	NMKeiding_Graph( "G_0_H0601", 0.9 )
	NMKeiding_Graph( "G_1_H2003", 1.1 )
	NMKeiding_Graph( "G_2_H1037", 0.7 )

End // NMKeiding_Graph_All

//****************************************************************//

Function /S NMKeiding_Graph( wName, ymax )
	String wName
	Variable ymax
	
	String txt, txt2
	Variable p601
	
	Variable overwriteMode = 1
	Variable currentChan = CurrentNMChannel()
	
	String fxn = NMFitStrGet( "FxnShort" )
	String gPrefix = "FT_" + CurrentNMFolderPrefix() + "Keiding" + wName + "_" + fxn
	String gName = NextGraphName( gPrefix, currentChan, overwriteMode )
	String gTitle = NMFolderListName( "" ) + " : Keiding " + wName + " : " + fxn + " Fits"
	
	NMFolderCheck( KeidingFolder )
	
	if ( !WaveExists( $wName ) )
		return ""
	endif
	
	strswitch( wName )
		case "G_0_H0601":
			txt = "\\Z10\rPatient #601\r"
			p601 = 1
			break
		case "G_1_H2003":
			txt = "\\Z10\rPatient #2003\r"
			break
		case "G_2_H1037":
			txt = "\\Z10\rPatient #1037\r"
			break
		default:
			return ""
	endswitch
	
	if ( p601 )
		txt += "\\sa+06\\s(" + wName + ") G(d)\r"
	endif
	
	String fName_chi3 = "KFit_" + wName + "_Chi3"
	String fName_chi3_mn = "MN_" + fName_chi3
	String fName_chi3_sd = "SD_" + fName_chi3
	String fName_gauss3 = "KFit_" + wName + "_Gauss3"
	String fName = "Fit_" + wName + "_LSE"
	String fName_mn = "MN_" + fName
	String fName_sd = "SD_" + fName
	
	DoWindow /K $gName
	Display /N=$gName/W=(328,183,945,611)/K=1 $wName as gTitle
	
	ModifyGraph mode($wName)=3
	ModifyGraph marker($wName)=19
	ModifyGraph rgb($wName)=(1,34817,52428)
	ModifyGraph msize($wName)=3
	ModifyGraph mrkThick($wName)=1.25
	
	if ( WaveExists( $fName_chi3 ) )
	
		AppendToGraph /W=$gName $fName_chi3
		ModifyGraph rgb($fName_chi3)=(0,0,0)
		
		if ( WaveExists( $fName_chi3_mn ) )
			Make /O/N=1 Y0 = 0
			AppendToGraph Y0 vs $fName_chi3_mn
			ErrorBars Y0 X,wave=($fName_chi3_sd,$fName_chi3_sd)
			ModifyGraph mode(Y0)=3
			ModifyGraph marker(Y0)=19
			ModifyGraph rgb(Y0)=(0,0,0)
			ModifyGraph msize(Y0)=2.5
			ModifyGraph mrkThick(Y0)=1.25
			ModifyGraph offset(Y0)={0,0.10*ymax}
			txt2 = " (\\s(Y0))"
		else
			txt2 = ""
		endif
	
		if ( p601 )
			txt += "\\sa+06\\s(" + fName_chi3 + ") 1972 MLE (K-Chi3)" + txt2 + "\r"
		endif
		
	endif
	
	if ( WaveExists( $fName_gauss3 ) )
		AppendToGraph /W=$gName $fName_gauss3
		ModifyGraph rgb($fName_gauss3)=(52428,1,1)
		ModifyGraph lStyle($fName_gauss3)=3
		if ( p601 )
			txt += "\\sa+06\\s(" + fName_gauss3 + ") 1972 MLE (K-Gauss3)\r"
		endif
	endif
	
	if ( WaveExists( $fName ) )
	
		AppendToGraph /W=$gName $fName
		ModifyGraph rgb($fName)=(1,34817,52428)
		ModifyGraph lstyle($fName)=2
		
		if ( WaveExists( $fName_mn ) )
			Make /O/N=1 Y1 = 0
			AppendToGraph Y1 vs $fName_mn
			ErrorBars Y1 X,wave=($fName_sd,$fName_sd)
			ModifyGraph mode(Y1)=3
			ModifyGraph marker(Y1)=19
			ModifyGraph rgb(Y1)=(1,34817,52428)
			ModifyGraph msize(Y1)=2.5
			ModifyGraph mrkThick(Y1)=1.25
			ModifyGraph offset(Y1)={0,0.05*ymax}
			txt2 = " (\\s(Y1))"
		else
			txt2 = ""
		endif
		
		if ( p601 )
			txt += "\\sa+06\\s(" + fName + ") 2023 LSE (K-Gauss3)" + txt2
		endif
		
	endif
	
	ModifyGraph margin(left)=44,margin(bottom)=36,margin(top)=25,margin(right)=25
	ModifyGraph lSize=1.25
	ModifyGraph fSize=10
	ModifyGraph standoff=0
	ModifyGraph axThick=1.25
	ModifyGraph axisOnTop=1
	ModifyGraph manTick(left)={0,0.2,0,1},manMinor(left)={1,50}
	ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={1,50}
	
	Label left PDF_YLabel( Keiding_G_Units )
	Label bottom "Liver cell nucleus diameter (" + Keiding_G_Units + ")"
	SetAxis left 0,ymax
	SetAxis bottom 4,11
	
	Legend/C/N=text0/J/F=0/B=1/X=0.00/Y=0.00 txt
	
	if ( p601 )
		TextBox/C/N=text1/F=0/B=1/A=LT/X=60.22/Y=70.54 "\\Z10\rT = " + num2str( Keiding_T ) + " " + Keiding_G_Units + " ≈ 1 u.d."
	endif
	
	NMWinCascade( gName )
	
	return gName

End // NMKeiding_Graph

//****************************************************************//
//
//	Demo functions for fitting G(d) of cerebellar GC somata and nuclei and MFT vesicles
//	Rothman et al 2023
//
//****************************************************************//

Function NMKeiding_GCsomata_G_Check( [ overwrite ] )
	Variable overwrite
	
	Variable xstart = 0.5 * GC_Somata_G_BinWidth
	
	NMFolderCheck( GC_Somata_Folder )
	
	if ( !overwrite && WaveExists( $"G_R1_SL1_1" ) )
		NMSet( wavePrefix="G_" )
		return 0
	endif
	
	NMHistoFreqList2Wave( GC_Somata_G_R1_SL1_1, "G_R1_SL1_1", xstart, GC_Somata_G_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( GC_Somata_G_R1_SL1_2, "G_R1_SL1_2", xstart, GC_Somata_G_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( GC_Somata_G_R1_SL2_1, "G_R1_SL2_1", xstart, GC_Somata_G_BinWidth, probability=1, overwrite=overwrite )
	
	NMHistoFreqList2Wave( GC_Somata_G_R5_SL1_1, "G_R5_SL1_1", xstart, GC_Somata_G_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( GC_Somata_G_R5_SL2_1, "G_R5_SL2_1", xstart, GC_Somata_G_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( GC_Somata_G_R5_SL3_1, "G_R5_SL3_1", xstart, GC_Somata_G_BinWidth, probability=1, overwrite=overwrite )
	
	NMHistoFreqList2Wave( GC_Somata_G_R6_SL1_1, "G_R6_SL1_1", xstart, GC_Somata_G_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( GC_Somata_G_R6_SL2_1, "G_R6_SL2_1", xstart, GC_Somata_G_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( GC_Somata_G_R6_SL2_2, "G_R6_SL2_2", xstart, GC_Somata_G_BinWidth, probability=1, overwrite=overwrite )
	
	NMSet( wavePrefix="G_" )
	NMChanXLabelSetAll( "GC soma 2D diamater (" + GC_Somata_G_Units + ")" )
	NMChanLabelSet( 0, 2, "y", PDF_YLabel( GC_Somata_G_Units ) )
	DoUpdate /W=$ChanGraphName(0)
	
	return 0
	
End // NMKeiding_GCsomata_G_Check

//****************************************************************//

Static Function NMKeiding_GCsomata_G_Num_Diam( wName )
	String wName
	
	strswitch( wName )
	
		case "G_R1_SL1_1":
			return FreqListSum( GC_Somata_G_R1_SL1_1 )
		case "G_R1_SL1_2":
			return FreqListSum( GC_Somata_G_R1_SL1_2 )
		case "G_R1_SL2_1":
			return FreqListSum( GC_Somata_G_R1_SL2_1 )
		
		case "G_R5_SL1_1":
			return FreqListSum( GC_Somata_G_R5_SL1_1 )
		case "G_R5_SL2_1":
			return FreqListSum( GC_Somata_G_R5_SL2_1 )
		case "G_R5_SL3_1":
			return FreqListSum( GC_Somata_G_R5_SL3_1 )
			
		case "G_R6_SL1_1":
			return FreqListSum( GC_Somata_G_R6_SL1_1 )
		case "G_R6_SL2_1":
			return FreqListSum( GC_Somata_G_R6_SL2_1 )
		case "G_R6_SL2_2":
			return FreqListSum( GC_Somata_G_R6_SL2_2 )
	
	endswitch
	
	return NaN

End // NMKeiding_GCsomata_G_Num_Diam

//****************************************************************//

Function NMKeiding_GCsoma_G_Fit()

	Variable wcnt, T_optical, num_diam
	String strvalue, wName

	NMKeiding_GCsomata_G_Check()
	
	Variable avalue = NMDoAlert( "Compute fits to 9 GC somata G(d)?", title="Keiding-model Fit Demo", alertType = 1 )
	
	if ( avalue != 1 )
		return 0
	endif
	
	NMFitKeidingInit()
	
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_coef = $NMFitWavePath( "coef" )
	
	for ( wcnt = 0 ; wcnt < NMNumWaves() ; wcnt += 1 )
	
		NMSet( waveNum=wcnt )
		wName = CurrentNMWaveName()
		
		strvalue = StringFromList( wcnt, GC_Somata_T_List )
		T_optical = str2num( StringFromList( 1, strvalue, "=" ) )
		
		FT_guess[ 0 ] = 6 // changed by NMKeidingGaussGuess
		FT_guess[ 1 ] = 0.5
		FT_guess[ 2 ] = 20
		FT_guess[ 3 ] = T_optical
		FT_guess[ 4 ] = NMKeiding_GCsomata_G_Num_Diam( wName )
	
		if ( NMFitWave() == 0 )
			NMFitSaveCurrent()
		endif
		
	endfor
	
	return 0

End // NMKeiding_GCsoma_G_Fit

//****************************************************************//

Function NMKeiding_GCnuclei_G_Check( [ overwrite ] )
	Variable overwrite
	
	Variable xstart = 0.5 * GC_Nuclei_G_BinWidth
	
	NMFolderCheck( GC_Nuclei_Folder )
	
	if ( !overwrite && WaveExists( $"G_M15_All" ) )
		NMSet( wavePrefix="G_" )
		return 0
	endif
	
	NMHistoFreqList2Wave( GC_Nuclei_G_M15_All, "G_M15_All", xstart, GC_Nuclei_G_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( GC_Nuclei_G_M18_All, "G_M18_All", xstart, GC_Nuclei_G_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( GC_Nuclei_G_M19_All, "G_M19_All", xstart, GC_Nuclei_G_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( GC_Nuclei_G_M21_All, "G_M21_All", xstart, GC_Nuclei_G_BinWidth, probability=1, overwrite=overwrite )
	
	NMSet( wavePrefix="G_" )
	NMChanXLabelSetAll( "GC nucleus 2D diamater (" + GC_Nuclei_G_Units + ")" )
	NMChanLabelSet( 0, 2, "y", PDF_YLabel( GC_Nuclei_G_Units ) )
	DoUpdate /W=$ChanGraphName(0)
	
	return 0
	
End // NMKeiding_GCnuclei_G_Check

//****************************************************************//

Static Function NMKeiding_GCnuclei_G_Num_Diam( wName )
	String wName
	
	strswitch( wName )
		case "G_M15_All":
			return FreqListSum( GC_Nuclei_G_M15_All )
		case "G_M18_All":
			return FreqListSum( GC_Nuclei_G_M18_All )
		case "G_M19_All":
			return FreqListSum( GC_Nuclei_G_M19_All )
		case "G_M21_All":
			return FreqListSum( GC_Nuclei_G_M21_All )
		case "G_2D_Nguyen":
			return FreqListSum( GC_Nuclei_G_Nguyen )
	endswitch
	
	return NaN

End // NMKeiding_GCnuclei_G_Num_Diam

//****************************************************************//

Function NMKeiding_GCnuclei_G_Fit()

	Variable wcnt, num_diam
	String wName

	NMKeiding_GCnuclei_G_Check()
	
	Variable avalue = NMDoAlert( "Compute fits to 4 GC nuclei G(d)?", title="Keiding-model Fit Demo", alertType = 1 )
	
	if ( avalue != 1 )
		return 0
	endif
	
	NMFitKeidingInit()
	
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_coef = $NMFitWavePath( "coef" )
	
	for ( wcnt = 0 ; wcnt < NMNumWaves() ; wcnt += 1 )
	
		NMSet( waveNum=wcnt )
		wName = CurrentNMWaveName()
		
		FT_guess[ 0 ] = 5 // changed by NMKeidingGaussGuess
		FT_guess[ 1 ] = 0.5
		FT_guess[ 2 ] = 15
		FT_guess[ 3 ] = GC_Nuclei_T
		FT_guess[ 4 ] = NMKeiding_GCnuclei_G_Num_Diam( wName )
	
		if ( NMFitWave() == 0 ) 
			NMFitSaveCurrent()
		endif
		
	endfor
	
	return 0

End // NMKeiding_GCnuclei_G_Fit

//****************************************************************//

Function NMKeiding_MFves_G_TEM_Check( [ overwrite ] )
	Variable overwrite
	
	Variable xstart = 0.5 * MFT_Vesicles_G_TEM_BinWidth
	
	NMFolderCheck( MFT_Vesicles_TEM_Folder )
	
	if ( !overwrite && WaveExists( $"G_M15_45" ) )
		NMSet( wavePrefix="G_" )
		return 0
	endif
		
	NMHistoFreqList2Wave( MFT_Vesicles_G_M15_45, "G_M15_45", xstart, MFT_Vesicles_G_TEM_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( MFT_Vesicles_G_M15_48, "G_M15_48", xstart, MFT_Vesicles_G_TEM_BinWidth, probability=1, overwrite=overwrite )
	
	NMHistoFreqList2Wave( MFT_Vesicles_G_M18_03, "G_M18_03", xstart, MFT_Vesicles_G_TEM_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( MFT_Vesicles_G_M18_10, "G_M18_10", xstart, MFT_Vesicles_G_TEM_BinWidth, probability=1, overwrite=overwrite )
	
	NMHistoFreqList2Wave( MFT_Vesicles_G_M19_26, "G_M19_26", xstart, MFT_Vesicles_G_TEM_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( MFT_Vesicles_G_M19_34, "G_M19_34", xstart, MFT_Vesicles_G_TEM_BinWidth, probability=1, overwrite=overwrite )
	
	NMHistoFreqList2Wave( MFT_Vesicles_G_M21_04, "G_M21_04", xstart, MFT_Vesicles_G_TEM_BinWidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( MFT_Vesicles_G_M21_19, "G_M21_19", xstart, MFT_Vesicles_G_TEM_BinWidth, probability=1, overwrite=overwrite )
	
	NMSet( wavePrefix="G_" )
	NMChanXLabelSetAll( "MFT vesicle 2D diamater (" + MFT_Vesicles_G_TEM_Units + ")" )
	NMChanLabelSet( 0, 2, "y", PDF_YLabel( MFT_Vesicles_G_TEM_Units ) )
	DoUpdate /W=$ChanGraphName(0)
	
	return 0
	
End // NMKeiding_MFves_G_TEM_Check

//****************************************************************//

Static Function NMKeiding_MFves_G_Num_Diam( wName )
	String wName
	
	strswitch( wName )
	
		case "G_M15_45":
			return FreqListSum( MFT_Vesicles_G_M15_45 )
		case "G_M15_48":
			return FreqListSum( MFT_Vesicles_G_M15_48 )
			
		case "G_M18_03":
			return FreqListSum( MFT_Vesicles_G_M18_03 )
		case "G_M18_10":
			return FreqListSum( MFT_Vesicles_G_M18_10 )
			
		case "G_M19_26":
			return FreqListSum( MFT_Vesicles_G_M19_26 )
		case "G_M19_34":
			return FreqListSum( MFT_Vesicles_G_M19_34 )
			
		case "G_M21_04":
			return FreqListSum( MFT_Vesicles_G_M21_04 )
		case "G_M21_19":
			return FreqListSum( MFT_Vesicles_G_M21_19 )
			
		case "G_ET10":
			return ( FreqListSum( MFT_Vesicles_G_ET10 ) / 3.0 ) // N/3 due to less sampling of F(d)
			
		case "G_ET11":
			return ( FreqListSum( MFT_Vesicles_G_ET11 ) / 3.0 ) // N/3 due to less sampling of F(d)
		
	endswitch
	
	return NaN

End // NMKeiding_MFves_G_Num_Diam

//****************************************************************//

Function NMKeiding_MFves_G_TEM_Fit()

	Variable wcnt, num_diam
	String wName

	NMKeiding_MFves_G_TEM_Check()
	
	Variable avalue = NMDoAlert( "Compute fits to 8 MFT vesicle TEM G(d)?", title="Keiding-model Fit Demo", alertType = 1 )
	
	if ( avalue != 1 )
		return 0
	endif
	
	NMFitKeidingInit()
	
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_coef = $NMFitWavePath( "coef" )
	
	for ( wcnt = 0 ; wcnt < NMNumWaves() ; wcnt += 1 )
	
		NMSet( waveNum=wcnt )
		wName = CurrentNMWaveName()
		
		FT_guess[ 0 ] = 45 // changed by NMKeidingGaussGuess
		FT_guess[ 1 ] = 4
		FT_guess[ 2 ] = 20
		FT_guess[ 3 ] = MFT_Vesicles_TEM_T
		FT_guess[ 4 ] = NMKeiding_MFves_G_Num_Diam( wName )
	
		if ( NMFitWave() == 0 )
			NMFitSaveCurrent()
		endif
		
	endfor
	
	return 0

End // NMKeiding_MFves_G_TEM_Fit

//****************************************************************//

Function NMKeiding_MFves_G_ET_Check( etID [ overwrite ] )
	String etID
	Variable overwrite
	
	Variable new, f_MN, f_SD
	String wName, fList, gList
	
	Variable xstart = 0.5 * MFT_Vesicles_G_ET_BinWidth
	
	strswitch( etID )
		case "ET10":
			fList = MFT_Vesicles_F_ET10
			gList = MFT_Vesicles_G_ET10
			f_MN = MFT_Vesicles_F_ET10_MN
			f_SD = MFT_Vesicles_F_ET10_SD
			break
		case "ET11":
			fList = MFT_Vesicles_F_ET11
			gList = MFT_Vesicles_G_ET11
			f_MN = MFT_Vesicles_F_ET11_MN
			f_SD = MFT_Vesicles_F_ET11_SD
			break
		default:
			Print "error: NMKeiding_MFves_G_ET_Check: unknown ET ID:", etID
			return -1
	endswitch
	
	NMFolderCheck( MFT_Vesicles_ET_Folder + "_" + etID )
	
	wName = "F_" + etID
	
	if ( overwrite || !WaveExists( $wName ) )
		NMHistoFreqList2Wave( fList, wName, xstart, MFT_Vesicles_G_ET_BinWidth, probability=1, overwrite=overwrite )
		Make /O/N=1 $"MN_" + wName = f_MN
		Make /O/N=1 $"SD_" + wName = f_SD
		NMSet( wavePrefix="F_" )
		NMChanXLabelSetAll( "MFT vesicle 3D diameter (" + MFT_Vesicles_G_ET_Units + ")" )
		NMChanLabelSet( 0, 2, "y", PDF_YLabel( MFT_Vesicles_G_ET_Units ) )
	endif
	
	wName = "G_" + etID
	
	if ( overwrite || !WaveExists( $wName ) )
		NMHistoFreqList2Wave( gList, wName, xstart, MFT_Vesicles_G_ET_BinWidth, probability=1, overwrite=overwrite )
		new = 1
	endif
	
	NMSet( wavePrefix="G_" )
	
	if ( new )
		NMChanXLabelSetAll( "MFT vesicle 2D diameter (" + MFT_Vesicles_G_ET_Units + ")" )
		NMChanLabelSet( 0, 2, "y", PDF_YLabel( MFT_Vesicles_G_ET_Units ) )
	endif
	
	DoUpdate /W=$ChanGraphName(0)
	
	return 0

End // NMKeiding_MFves_G_ET_Check

//****************************************************************//

Function NMKeiding_MFves_G_ET_Fit( etID [ graph ] )
	String etID
	Variable graph
	
	Variable fit_mn, fit_sd, num_diam, error
	String wName, fName, fName2

	NMKeiding_MFves_G_ET_Check( etID )
	
	Variable avalue = NMDoAlert( "Compute fit to MFT vesicle ET G(d)?", title="Keiding-model Fit Demo", alertType = 1 )
	
	if ( avalue != 1 )
		return 0
	endif
	
	NMFitKeidingInit()
	
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_coef = $NMFitWavePath( "coef" )
	
	NMSet( waveNum=0 )
	wName = CurrentNMWaveName()
	
	FT_guess[ 0 ] = 45 // changed by NMKeidingGaussGuess
	FT_guess[ 1 ] = 4
	FT_guess[ 2 ] = 20
	FT_guess[ 3 ] = MFT_Vesicles_ET_T
	FT_guess[ 4 ] = NMKeiding_MFves_G_Num_Diam( wName )
	
	error = NMFitWave()
	
	if ( error > 0 )
		NMHistory( "fit error: NMKeiding_MFves_G_ET_Fit" )
		return error
	endif
	
	NMFitSaveCurrent()
	
	Wave FT_coef = $NMFitWavePath( "coef" )
	fit_mn = FT_coef[0]
	fit_sd = FT_coef[1]
	
	fName = "Fit_G_" + etID
	fName2 = "F_" + fName
	
	Make /D/O/N=1 $"MN_" + fName2 = fit_mn
	Make /D/O/N=1 $"SD_" + fName2 = fit_sd
	
	if ( WaveExists( $fName ) )
		Duplicate /O $fName $fName2
		Wave wtemp = $fName2
		wtemp = Gauss( x, fit_mn, fit_sd )
	endif
	
	if ( !graph )
		return 0
	endif
	
	NMKeiding_MFves_G_ET_Fit_Graph( etID )
	
	return 0

End // NMKeiding_MFves_G_ET_Fit

//****************************************************************//

Function /S NMKeiding_MFves_G_ET_Fit_Graph( etID )
	String etID
	
	Variable phi_measured
	
	String df = "root:" + MFT_Vesicles_ET_Folder + "_" + etID + ":"
	String fdf = df + "Fit_KeidingGauss_G_All_A:"
	
	Variable overwriteMode = 1
	Variable currentChan = CurrentNMChannel()
	Variable left_max = 0.11
	
	String fxn = NMFitStrGet( "FxnShort" )
	String gPrefix = "FT_" + CurrentNMFolderPrefix() + etID + "_" + fxn
	String gName = NextGraphName( gPrefix, currentChan, overwriteMode )
	String gTitle = NMFolderListName( "" ) + " : MFT vesicle " + etID + " G(d) : " + fxn + " Fit"
	
	strswitch( etID )
		case "ET10":
			phi_measured = MFT_Vesicles_ET10_Phi_MN
			break
		case "ET11":
			left_max = 0.16
			phi_measured = MFT_Vesicles_ET11_Phi_MN
			break
		default:
			return ""
	endswitch
	
	NMFolderCheck( MFT_Vesicles_ET_Folder + "_" + etID )
	
	if ( !WaveExists( $"G_" + etID ) )
		return ""
	endif
	
	Wave F_ = $"F_" + etID
	Wave MN_F_ = $"MN_F_" + etID
	Wave SD_F_ = $"SD_F_" + etID
	
	Wave G_ = $"G_" + etID
	
	Wave Fit_G_ = $"Fit_G_" + etID
	Wave F_Fit_G_ = $"F_Fit_G_" + etID
	Wave MN_F_Fit_G_ = $"MN_F_Fit_G_" + etID
	Wave SD_F_Fit_G_ = $"SD_F_Fit_G_" + etID
	Wave fit_phi = $fdf + "FT_Keidi_Phi_GAll_A0"
	
	Variable deltaD_MN = 100 * ( MN_F_Fit_G_[ 0 ] - MN_F_[0] ) / MN_F_[0] // %
	Variable deltaD_SD = 100 * ( SD_F_Fit_G_[ 0 ] - SD_F_[0] ) / SD_F_[0] // %
	Variable deltaPhi = fit_phi[0] - phi_measured // degrees
	
	String deltaD_MN_str, deltaD_SD_str
	
	sprintf deltaD_MN_str, "%.1f", deltaD_MN
	sprintf deltaD_SD_str, "%.1f", deltaD_SD
	
	Make /O/N=1 Y0 = 0
	Make /O/N=1 Y1 = 0
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=(294,216,891,654) F_,G_,Fit_G_,F_Fit_G_ as gTitle
	
	AppendToGraph Y0 vs MN_F_
	AppendToGraph Y1 vs MN_F_Fit_G_
	
	ModifyGraph margin(left)=58,margin(bottom)=44,margin(top)=25,margin(right)=25
	ModifyGraph mode(Y0)=3,mode(Y1)=3
	ModifyGraph marker(Y0)=19,marker(Y1)=19
	ModifyGraph mode($"G_"+etID)=3,marker($"G_"+etID)=19,msize($"G_"+etID)=3
	ModifyGraph lSize=1.25
	ModifyGraph lStyle($"F_Fit_G_"+etID)=3
	ModifyGraph rgb($"F_"+etID)=(0,0,0),rgb($"G_"+etID)=(19675,39321,1),rgb($"Fit_G_"+etID)=(52428,1,1),rgb($"F_Fit_G_"+etID)=(52428,1,1)
	ModifyGraph rgb(Y0)=(0,0,0),rgb(Y1)=(52428,1,1)
	ModifyGraph msize(Y0)=2.5,msize(Y1)=2.5
	ModifyGraph mrkThick(Y0)=1.25,mrkThick(Y1)=1.25
	ModifyGraph offset(Y0)={0,0.012},offset(Y1)={0,0.006}
	ModifyGraph fSize=10
	ModifyGraph standoff=0
	ModifyGraph axThick=1.25
	ModifyGraph manTick(left)={0,0.05,0,2},manMinor(left)={4,50}
	ModifyGraph manTick(bottom)={0,10,0,0},manMinor(bottom)={1,50}
	ModifyGraph axisOnTop=1
	
	// ModifyGraph mode(G_ET10)=3,marker(G_ET10)=19,msize(G_ET10)=3
	
	Label left PDF_YLabel( MFT_Vesicles_G_ET_Units )
	Label bottom "MFT vesicle diameter (" + MFT_Vesicles_G_ET_Units + ")"
	SetAxis left*,left_max
	SetAxis bottom 0,65
	ErrorBars Y0 X,wave=(SD_F_,SD_F_)
	ErrorBars Y1 X,wave=(SD_F_Fit_G_,SD_F_Fit_G_)
	
	String txt = "\\Z12\r\\s(F_" + etID + ") F(d) (\\s(Y0))\r"
	txt += "\\sa+12\\s(G_" + etID + ") G(d)\r"
	txt += "\\sa+12\\s(Fit_G_" + etID + ") Fit to G(d)\r"
	txt += "\\sa+12\\s(F_Fit_G_" + etID + ") F(d) from fit (\\s(Y1))\r"
	txt += "\\sa+48∆μ\\BD\\M\\Z12 = " + deltaD_MN_str + "%\r"
	txt += "\\sa+12∆σ\\BD\\M\\Z12 = " + deltaD_SD_str + "%\r"
	txt += "\\sa+12∆Φ = " + num2istr( round( deltaPhi ) ) + "°"
	
	Legend/C/N=text0/J/F=0/M/A=MC/X=-31.31/Y=23.42 txt
	
	NMWinCascade( gName )
	
	return gName
	
End // NMKeiding_MFves_G_ET_Fit_Graph

//****************************************************************//

Function NMKeiding_GCnuclei_Nguyen_G_Check( [ overwrite ] )
	Variable overwrite
	
	Variable new
	String wName
	
	Variable xstart = 0.5 * GC_Nuclei_G_BinWidth
	
	String fList = GC_Nuclei_F_Nguyen
	String gList = GC_Nuclei_G_Nguyen
	
	NMFolderCheck( GC_Nuclei_Nguyen_Folder )
	
	wName = "F_3D_Nguyen"
	
	if ( overwrite || !WaveExists( $wName ) )
		NMHistoFreqList2Wave( fList, wName, xstart, GC_Nuclei_G_BinWidth, probability=1, overwrite=overwrite )
		Make /O/N=1 $"MN_" + wName = GC_Nuclei_F_Nguyen_MN
		Make /O/N=1 $"SD_" + wName = GC_Nuclei_F_Nguyen_SD
		NMSet( wavePrefix="F_" )
		NMChanXLabelSetAll( "GC nuclei 3D diameter (" + GC_Nuclei_G_Units + ")" )
		NMChanLabelSet( 0, 2, "y", PDF_YLabel( GC_Nuclei_G_Units ) )
	endif
	
	wName = "G_2D_Nguyen"
	
	if ( overwrite || !WaveExists( $wName ) )
		NMHistoFreqList2Wave( gList, wName, xstart, GC_Nuclei_G_BinWidth, probability=1, overwrite=overwrite )
		new = 1
	endif
	
	NMSet( wavePrefix="G_" )
	
	if ( new )
		NMChanXLabelSetAll( "GC nuclei 2D diameter (" + GC_Nuclei_G_Units + ")" )
		NMChanLabelSet( 0, 2, "y", PDF_YLabel( GC_Nuclei_G_Units ) )
	endif
	
	DoUpdate /W=$ChanGraphName(0)
	
	return 0

End // NMKeiding_GCnuclei_Nguyen_G_Check

//****************************************************************//

Function NMKeiding_GCnuclei_Nguyen_G_Fit( [ graph ] )
	Variable graph
	
	Variable fit_mn, fit_sd, num_diam, error
	String wName, fName, fName2

	NMKeiding_GCnuclei_Nguyen_G_Check()
	
	Variable avalue = NMDoAlert( "Compute fit to GC nuclei G(d) of Nguyen et al?", title="Keiding-model Fit Demo", alertType = 1 )
	
	if ( avalue != 1 )
		return 0
	endif
	
	NMFitKeidingInit()
	
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_coef = $NMFitWavePath( "coef" )
	
	NMSet( waveNum=0 )
	wName = CurrentNMWaveName()
	
	FT_guess[ 0 ] = 6 // changed by NMKeidingGaussGuess
	FT_guess[ 1 ] = 0.5
	FT_guess[ 2 ] = 15
	FT_guess[ 3 ] = GC_Nuclei_Nguyen_T
	FT_guess[ 4 ] = NMKeiding_GCnuclei_G_Num_Diam( wName )
	
	error = NMFitWave()
	
	if ( error > 0 )
		NMHistory( "fit error: NMKeiding_MFves_G_ET_Fit" )
		return error
	endif
	
	NMFitSaveCurrent()
	
	Wave FT_coef = $NMFitWavePath( "coef" )
	fit_mn = FT_coef[0]
	fit_sd = FT_coef[1]
	
	fName = "Fit_G_2D_Nguyen"
	fName2 = "F_" + fName
	
	Make /D/O/N=1 $"MN_" + fName2 = fit_mn
	Make /D/O/N=1 $"SD_" + fName2 = fit_sd
	
	if ( WaveExists( $fName ) )
		Duplicate /O $fName $fName2
		Wave wtemp = $fName2
		wtemp = Gauss( x, fit_mn, fit_sd )
	endif
	
	if ( !graph )
		return 0
	endif
	
	NMKeiding_GCnuclei_Nguyen_G_Fit_Graph()
	
	return 0

End // NMKeiding_GCnuclei_Nguyen_G_Fit

//****************************************************************//

Function /S NMKeiding_GCnuclei_Nguyen_G_Fit_Graph()
	
	String df = "root:GC_Nuclei_Nguyen:"
	String fdf = df + "Fit_KeidingGauss_G_All_A:"
	
	Variable overwriteMode = 1
	Variable currentChan = CurrentNMChannel()
	Variable left_max = 0.9
	
	String fxn = NMFitStrGet( "FxnShort" )
	String gPrefix = "FT_" + CurrentNMFolderPrefix() + "GCNucleiG_" + fxn
	String gName = NextGraphName( gPrefix, currentChan, overwriteMode )
	String gTitle = NMFolderListName( "" ) + " : GC Nuclei G(d) Nguyen : " + fxn + " Fit"
	
	NMFolderCheck( GC_Nuclei_Nguyen_Folder )
	
	if ( !WaveExists( $"G_2D_Nguyen" ) )
		return ""
	endif
	
	String f3D_Name = "F_3D_Nguyen"
	String g2D_Name = "G_2D_Nguyen"
	
	Wave F_ = $f3D_Name
	Wave MN_F_ = $"MN_" + f3D_Name
	Wave SD_F_ = $"SD_" + f3D_Name
	
	Wave G_ = $g2D_Name
	
	Wave Fit_G_ = $"Fit_" + g2D_Name
	Wave F_Fit_G_ = $"F_Fit_" + g2D_Name
	Wave MN_F_Fit_G_ = $"MN_F_Fit_" + g2D_Name
	Wave SD_F_Fit_G_ = $"SD_F_Fit_" + g2D_Name
	Wave fit_phi = $fdf + "FT_Keidi_Phi_GAll_A0"
	
	Variable deltaD_MN = 100 * ( MN_F_Fit_G_[ 0 ] - MN_F_[0] ) / MN_F_[0] // %
	Variable deltaD_SD = 100 * ( SD_F_Fit_G_[ 0 ] - SD_F_[0] ) / SD_F_[0] // %
	
	String deltaD_MN_str, deltaD_SD_str
	
	sprintf deltaD_MN_str, "%.1f", deltaD_MN
	sprintf deltaD_SD_str, "%.1f", deltaD_SD
	
	Make /O/N=1 Y0 = 0
	Make /O/N=1 Y1 = 0
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=(294,216,891,654) F_,G_,Fit_G_,F_Fit_G_ as gTitle
	
	AppendToGraph Y0 vs MN_F_
	AppendToGraph Y1 vs MN_F_Fit_G_
	
	ModifyGraph margin(left)=58,margin(bottom)=44,margin(top)=25,margin(right)=25
	ModifyGraph mode(Y0)=3,mode(Y1)=3
	ModifyGraph marker(Y0)=19,marker(Y1)=19
	ModifyGraph mode($g2D_Name)=3,marker($g2D_Name)=19,msize($g2D_Name)=3
	ModifyGraph lSize=1.25
	ModifyGraph lStyle($"F_Fit_"+g2D_Name)=3
	ModifyGraph rgb($f3D_Name)=(0,0,0),rgb($g2D_Name)=(19675,39321,1),rgb($"Fit_"+g2D_Name)=(52428,1,1),rgb($"F_Fit_"+g2D_Name)=(52428,1,1)
	ModifyGraph rgb(Y0)=(0,0,0),rgb(Y1)=(52428,1,1)
	ModifyGraph msize(Y0)=2.5,msize(Y1)=2.5
	ModifyGraph mrkThick(Y0)=1.25,mrkThick(Y1)=1.25
	ModifyGraph offset(Y0)={0,0.08},offset(Y1)={0,0.04}
	ModifyGraph fSize=10
	ModifyGraph standoff=0
	ModifyGraph axThick=1.25
	ModifyGraph manTick(left)={0,0.2,0,1},manMinor(left)={1,50}
	ModifyGraph manTick(bottom)={0,2,0,0},manMinor(bottom)={3,50}
	ModifyGraph axisOnTop=1
	
	Label left PDF_YLabel( GC_Nuclei_G_Units )
	Label bottom "GC nucleus diameter (" + GC_Nuclei_G_Units + ")"
	SetAxis left*,left_max
	SetAxis bottom 0,9.5
	ErrorBars Y0 X,wave=(SD_F_,SD_F_)
	ErrorBars Y1 X,wave=(SD_F_Fit_G_,SD_F_Fit_G_)
	
	String txt = "\\Z12\rTEM z-stack of GC nuclei\r"
	txt += "\\sa+12\\s(" + f3D_Name +  ") F(d) (\\s(Y0))\r"
	txt += "\\sa+12\\s(" + g2D_Name + ") G(d) blind\r"
	txt += "\\sa+12\\s(Fit_" + g2D_Name + ") Fit to G(d)\r"
	txt += "\\sa+12\\s(F_Fit_" + g2D_Name + ") F(d) from fit (\\s(Y1))\r"
	txt += "\\sa+48∆μ\\BD\\M\\Z12 = " + deltaD_MN_str + "%\r"
	txt += "\\sa+12∆σ\\BD\\M\\Z12 = " + deltaD_SD_str + "%\r"
	txt += "\\sa+12Fit Φ = " + num2istr( round( fit_phi[0] ) ) + "°"
	
	Legend/C/N=text0/J/F=0/M/A=MC/X=-31.31/Y=23.42 txt
	
	NMWinCascade( gName )
	
	return gName
	
End // NMKeiding_GCnuclei_Nguyen_G_Fit_Graph

//****************************************************************//
//
//	Demo functions for fitting simulated G(d) from D3D
//	Rothman et al 2023
//
//****************************************************************//

Function NMKeiding_D3D_G_Check( [ overwrite ] )
	Variable overwrite
	
	Variable binwidth, xstart
	Variable diam_dx, diam_max, diam_pnts = 500
	String diam_units, fName = "F_Gauss"
	
	NMFolderCheck( D3D_Folder )
	
	if ( !overwrite && WaveExists( $"G_T0_P20_41" ) )
		NMSet( wavePrefix="G_" )
		return 0
	endif
	
	if ( D3D_G_Convert2UD )
		binwidth = D3D_G_BinWidth / D3D_F_MN
		diam_units = "u.d."
	else
		binwidth = D3D_G_BinWidth
		diam_units = D3D_G_Units
	endif
	
	xstart = 0.5 * binwidth
	
	NMHistoFreqList2Wave( D3D_G_T0_P20_41, "G_T0_P20_41", xstart, binwidth, probability=1, overwrite=overwrite )
	NMHistoFreqList2Wave( D3D_G_T1_P70_41, "G_T1_P70_41", xstart, binwidth, probability=1, overwrite=overwrite )
	
	NMSet( wavePrefix="G_" )
	NMChanXLabelSetAll( "Particle 2D diamater (" + diam_units + ")" )
	NMChanLabelSet( 0, 2, "y", PDF_YLabel( diam_units ) )
	
	diam_max = rightx( $"G_T0_P20_41" )
	diam_dx = diam_max / diam_pnts
	
	Make /D/O/N=(diam_pnts) $fName
	Wave ftemp = $fName
	Setscale /P x 0, diam_dx, ftemp
	NM_PDFunits( fName, diam_units )
	
	if ( D3D_G_Convert2UD )
		ftemp = Gauss( x, 1, D3D_F_SD / D3D_F_MN )
		Make /D/O/N=1 MN_F_Gauss = 1
		Make /D/O/N=1 SD_F_Gauss = D3D_F_SD / D3D_F_MN
	else
		ftemp = Gauss( x, D3D_F_MN, D3D_F_SD )
		Make /D/O/N=1 MN_F_Gauss = D3D_F_MN
		Make /D/O/N=1 SD_F_Gauss = D3D_F_SD
	endif
	
	DoUpdate /W=$ChanGraphName(0)
	
	return 0
	
End // NMKeiding_D3D_G_Check

//****************************************************************//

Static Function NMKeiding_D3D_G_Num_Diam( wName )
	String wName
	
	strswitch( wName )
		case "G_T0_P20_41":
			return FreqListSum( D3D_G_T0_P20_41 )
		case "G_T1_P70_41":
			return FreqListSum( D3D_G_T1_P70_41 )
	endswitch

	return NaN
	
End // NMKeiding_D3D_G_Num_Diam

//****************************************************************//

Function NMKeiding_D3D_G_Fit( [ graph ] )
	Variable graph
	
	Variable wcnt, numWaves, diam_mn, diam_sd, T1, num_diam
	String wName, fName, fName2, wList = ""
	
	NMKeiding_D3D_G_Check()
	
	Variable avalue = NMDoAlert( "Compute fits to simulated G(d)?", title="Keiding-model Fit Demo", alertType = 1 )
	
	if ( avalue != 1 )
		return 0
	endif
	
	NMFitKeidingInit()
	
	Wave FT_guess = $NMFitWavePath( "guess" )
	Wave FT_coef = $NMFitWavePath( "coef" )
	
	numWaves = NMNumWaves()
	
	if ( D3D_G_Convert2UD )
		diam_mn = 1
		diam_sd = D3D_F_SD / D3D_F_MN
		T1 = 1 
	else
		diam_mn = D3D_F_MN
		diam_sd = D3D_F_SD
		T1 = D3D_F_MN
	endif
	
	for ( wcnt = 0 ; wcnt < numWaves ; wcnt += 1 )
	
		NMSet( waveNum=wcnt )
		
		wName = CurrentNMWaveName()
		fName = "Fit_" + wName
		fName2 = "F_" + fName
		wList += wName + ";"
		
		FT_guess[ 0 ] = diam_mn * 0.95 // changed by NMKeidingGaussGuess
		FT_guess[ 1 ] = diam_sd * 1.05
		FT_guess[ 2 ] = 20 * 0.9
		
		if ( strsearch( wName, "_T0_", 0 ) > 0 )
			FT_guess[ 3 ] = 0
		elseif ( strsearch( wName, "_T1_", 0 ) > 0 )
			FT_guess[ 3 ] = T1
		else
			return -1
		endif
		
		FT_guess[ 4 ] = NMKeiding_D3D_G_Num_Diam( wName )
	
		if ( NMFitWave() > 0 )
			continue
		endif
		
		NMFitSaveCurrent()
		
		if ( WaveExists( $fName ) )
			Duplicate /O $fname $fName2
			Wave ftemp = $fName2
			ftemp = Gauss( x, FT_coef[ 0 ], FT_coef[ 1 ] )
		endif
		
		Make /D/O/N=1 $"MN_" + fName2 = FT_coef[ 0 ]
		Make /D/O/N=1 $"SD_" + fName2 = FT_coef[ 1 ]
		
	endfor
	
	if ( !graph )
		return 0
	endif
	
	for ( wcnt = 0 ; wcnt < ItemsInList( wList ) ; wcnt += 1 )
		wName = StringFromList( wcnt, wList )
		NMKeiding_D3D_G_Fit_Graph( wName )
	endfor

	return 0

End // NMKeiding_D3D_G_Fit

//****************************************************************//

Function /S NMKeiding_D3D_G_Fit_Graph( wName )
	String wName
	
	Variable lx, mr, mg, mb
	String TP
	
	Variable overwriteMode = 1
	Variable currentChan = CurrentNMChannel()
	
	String fxn = NMFitStrGet( "FxnShort" )
	String gPrefix = "FT_" + CurrentNMFolderPrefix() + "D3D" + wName + "_" + fxn
	String gName = NextGraphName( gPrefix, currentChan, overwriteMode )
	String gTitle = NMFolderListName( "" ) + " : D3D " + wName + " : " + fxn + " Fit"
	
	if ( strsearch( wName, "_T0_P20", 0 ) > 0 )
		TP = "T = 0 u.d., ϕ = 20°"
		gTitle += ", "
		lx = 0
		mr = 19675
		mg = 39321
		mb = 1
	elseif ( strsearch( wName, "_T1_P70", 0 ) > 0 )
		TP = "T = 1 u.d., ϕ = 70°"
		lx = 0.4
		mr = 1
		mg = 34817
		mb = 52428
	endif
	
	gTitle += ", " + TP
	
	if ( !WaveExists( $wName ) || !WaveExists( $"F_Gauss" ))
		return ""
	endif
	
	Wave F_Gauss, MN_F_Gauss, SD_F_Gauss
	
	Wave G_ = $wName
	Wave Fit_G_ = $"Fit_" + wName
	Wave F_Fit_G_ = $"F_Fit_" + wName
	Wave MN_F_Fit_G_ = $"MN_F_Fit_" + wName
	Wave SD_F_Fit_G_ = $"SD_F_Fit_" + wName
	
	Make /O/N=1 Y0 = 0
	Make /O/N=1 Y1 = 0
	
	DoWindow /K $gName
	Display /K=1/N=$gName/W=(177,292,635,597) F_Gauss,Fit_G_,G_,F_Fit_G_ as gTitle
	AppendToGraph Y0 vs MN_F_Gauss
	AppendToGraph Y1 vs MN_F_Fit_G_
	
	ModifyGraph margin(left)=36,margin(bottom)=42,margin(top)=21,margin(right)=21
	ModifyGraph mode($wName)=3,mode(Y0)=3,mode(Y1)=3
	ModifyGraph marker($wName)=19,marker(Y0)=19,marker(Y1)=8
	ModifyGraph lSize(F_Gauss)=1.25,lSize($"Fit_"+wName)=1.25,lSize($"F_Fit_"+wName)=1.25
	ModifyGraph lStyle($"F_Fit_"+wName)=3
	ModifyGraph rgb(F_Gauss)=(0,0,0),rgb($"Fit_"+wName)=(52428,1,1),rgb($wName)=(mr,mg,mb)
	ModifyGraph rgb($"F_Fit_"+wName)=(52428,1,1),rgb(Y0)=(0,0,0),rgb(Y1)=(52428,1,1)
	ModifyGraph msize($wName)=3,msize(Y0)=2.5,msize(Y1)=2.5
	ModifyGraph mrkThick($wName)=1.25,mrkThick(Y0)=1.25,mrkThick(Y1)=1.25
	ModifyGraph opaque(Y1)=1
	ModifyGraph offset(Y0)={0,0.5},offset(Y1)={0,0.25}
	ModifyGraph fSize=10
	ModifyGraph standoff=0
	ModifyGraph axThick=1.25
	ModifyGraph axisOnTop=1
	
	Label left PDF_YLabel( D3D_G_Units )
	Label bottom "Unit diameters (" + D3D_G_Units + ")"
	SetAxis left 0,5
	SetAxis bottom lx,1.4
	ErrorBars Y0 X,wave=(SD_F_Gauss,SD_F_Gauss)
	ErrorBars Y1 X,wave=(SD_F_Fit_G_,SD_F_Fit_G_)
	
	String txt = "\\Z12\r" + TP + "\r"
	txt += "\\sa+12\\s(F_Gauss) F(d) (\\s(Y0))\r"
	txt += "\\sa+12\\s(" + wName + ") Sim G(d)\r"
	txt += "\\sa+12\\s(Fit_" + wName + ") Fit to G(d)\r"
	txt += "\\sa+12\\s(F_Fit_" + wName + ") F(d) from fit (\\s(Y1))"
	
	Legend/C/N=text0/J/F=0/M/X=62.97/Y=12.18 txt
	
	NMWinCascade( gName )
	
	return gName
	
End // NMKeiding_D3D_G_Fit_Graph

//****************************************************************//

Function FreqListSum( freqList )
	String freqList

	Variable icnt, count = 0
	
	for ( icnt = 0 ; icnt < ItemsInList( freqList ) ; icnt += 1 )
		count += str2num( StringFromList( icnt, freqList ) )
	endfor
	
	return count

End // FreqListSum

//**************************************************************** //

Static Function FT_Hold_Reset()

	String fit_hold = NMFitWavePath( "hold" )
	Wave FT_hold = $fit_hold
	
	FT_hold = NaN
	FT_hold[ 3 ] = 1

End // FT_Hold_Reset

//****************************************************************//

Static Function /S G_Normalize_UD( wName,  diam3D_MN_true, overwrite )
	String wName
	Variable diam3D_MN_true // = 46
	Variable overwrite
	
	String wName2 = "N" + wName
	
	if ( !WaveExists( $wName ) )
		return ""
	endif
	
	if ( ( numtype( diam3D_MN_true ) > 0 ) || ( diam3D_MN_true <= 0 ) )
		return ""
	endif
	
	Variable dx_old = deltax( $wName )
	Variable lx_old = leftx( $wName )

	Variable dx_new = dx_old / diam3D_MN_true
	Variable lx_new = lx_old / diam3D_MN_true
	
	Duplicate /O $wName $wName2
	
	Wave wtemp = $wName2
	
	Setscale /P x lx_new, dx_new, wtemp
	
	wtemp *= diam3D_MN_true
	
	if ( overwrite )
		Duplicate /O $wName2 $wName
		KillWaves /Z $wName2
		return wName
	endif
	
	return wName2

End // G_Normalize_UD

//**************************************************************** //

Static Function NMFolderCheck( folderName )
	String folderName
	
	if ( !StringMatch( folderName, CurrentNMFolder( 0 ) ) )
		NMSet( folder=folderName )
	endif
	
End // NMFolderCheck

//**************************************************************** //

Static Function NM_PDFunits( wName, xunits )
	String wName
	String xunits
	
	String yunits = "PDF (/" + xunits + ")"
	
	NMNoteType( wName, "NMWave", xunits, yunits, "" )

End // NM_PDFunits

//**************************************************************** //

Static Function /S PDF_YLabel( diam_units )
	String diam_units
	
	return "Probability density (" + diam_units + "\\S-1\\M)"
	
End // PDF_YLabel

//**************************************************************** //

Static Function NMFitKeidingInit( [ fxn, fitPoints ] )
	String fxn
	Variable fitPoints
	
	if ( ParamIsDefault( fxn ) )
		fxn = "NMKeidingGauss"
	endif
	
	if ( ParamIsDefault( fitPoints ) )
		fitPoints = 1000
	endif

	NMSet( tab="Fit" )
	NMFitSet( fxn=fxn )
	NMFitSet( xbgn=-inf, xend=inf )
	NMFitSet( fitPoints=fitPoints )
	NMFitSet( printResults=1 )
	NMConfigVarSet( "Fit", "KeidingGuessAuto", 1 )
	FT_Hold_Reset()
	NMFitClearAll()
	
End // NMFitKeidingInit
	
//**************************************************************** //



