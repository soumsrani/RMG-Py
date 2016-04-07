# Data sources		
database(		
    thermoLibraries = ['KlippensteinH2O2','primaryThermoLibrary','DFT_QCI_thermo','CBS_QB3_1dHR'],		
    reactionLibraries = [],		
    seedMechanisms = ['Natgas_tol0.5'],		
    kineticsDepositories = ['training'],		
    kineticsFamilies = 'default',		
    kineticsEstimator = 'rate rules',		
)		
		
generatedSpeciesConstraints(		
    allowed=['seed mechanisms'],		
    maximumOxygenAtoms=4,		
    maximumRadicalElectrons=2,		
)		
		
		
# List of species		
species(		
    label='CH4',		
    reactive=True,		
    structure=SMILES("C"),		
)		
		
species(		
    label='O2',		
    reactive=True,		
    structure=SMILES('[O][O]'),		
)		
		
species(		
    label='N2',		
    reactive=False,		
    structure=SMILES("N#N"),		
)		
		
species(		
    label='AC3H4',		
    reactive=True,		
        structure = adjacencyList(		
  """		
  1 C u0 p0 c0 {2,D} {4,S} {5,S}		
  2 C u0 p0 c0 {1,D} {3,D}		
  3 C u0 p0 c0 {2,D} {6,S} {7,S}		
  4 H u0 p0 c0 {1,S}		
  5 H u0 p0 c0 {1,S}		
  6 H u0 p0 c0 {3,S}		
  7 H u0 p0 c0 {3,S}		
  """),		
)		
		
		
species(		
    label='C3H8',		
    reactive=True,		
        structure = adjacencyList(		
  """		
  1  C u0 p0 c0 {2,S} {4,S} {5,S} {6,S}		
  2  C u0 p0 c0 {1,S} {3,S} {10,S} {11,S}		
  3  C u0 p0 c0 {2,S} {7,S} {8,S} {9,S}		
  4  H u0 p0 c0 {1,S}		
  5  H u0 p0 c0 {1,S}		
  6  H u0 p0 c0 {1,S}		
  7  H u0 p0 c0 {3,S}		
  8  H u0 p0 c0 {3,S}		
  9  H u0 p0 c0 {3,S}		
  10 H u0 p0 c0 {2,S}		
  11 H u0 p0 c0 {2,S}		
  """),		
)		
		
species(		
    label='CO2',		
    reactive=True,		
    structure=SMILES('O=C=O'),		
)		
		
species(		
    label='C2H6',		
    reactive=True,		
    structure=SMILES('CC'),		
)		
		
species(		
    label='C4H10',		
    reactive=True,		
    structure=SMILES('CCCC'),		
)		
		
species(		
    label='iC5H12',		
    reactive=True,		
    structure=SMILES('CCC(C)C'),		
)		
		
species(		
    label='C6H14',		
    reactive=True,		
    structure=SMILES('CCCCCC'),		
)		
		
species(		
    label='H',		
    reactive=True,		
    structure=SMILES('[H]'),		
)		
		
species(		
    label='O',		
    reactive=True,		
    structure=SMILES('[O]'),		
)		
		
species(		
    label='OH',		
    reactive=True,		
    structure=SMILES('[OH]'),		
)		
		
species(		
    label='H2',		
    reactive=True,		
    structure=SMILES('[H][H]'),		
)		
		
species(		
    label='H2O',		
    reactive=True,		
    structure=SMILES('O'),		
)		
		
species(		
    label='HO2',		
    reactive=True,		
    structure=SMILES('[O]O'),		
)		
		
species(		
    label='CO',		
    reactive=True,		
    structure=SMILES('[C-]#[O+]'),		
)		
				
species(		
    label='C6H12',		
    reactive=True,		
    structure=SMILES('C=CCCCC'),		
)		
		
species(		
    label='C5H12',		
    reactive=True,		
    structure=SMILES('CCCCC'),		
)		
		
species(		
    label='Butanol',		
    reactive=True,		
    structure=SMILES('CCCCO'),		
)		
		
species(		
    label='iC4H8',		
    reactive=True,		
    structure=SMILES('C=C(C)C'),		
)		
		
species(		
    label='2C4H8',		
    reactive=True,		
    structure=SMILES('CC=CC'),		
)		
		
species(		
    label='Cyclohexane',		
    reactive=True,		
    structure=SMILES('C1CCCCC1'),		
)

species(		
    label='C3H3',		
    reactive=True,		
    structure=SMILES('C#C[CH2]'),		
)

# Bath gas
species(
    label='Ar',
    reactive=False,
    structure=InChI("InChI=1S/Ar"),
)
	
# Reaction systems		
		
simpleReactor(		
    temperature=(2080,'K'),		
    pressure=(1.5,'atm'),		
    initialMoleFractions={		
"CH4": 	0.214	,
 "O2":	0.0121	,
 "AC3H4":	0.0000933	,
 "C3H8":	0.00063	,
"H": 	0.0072	,
 "O": 	0.00252	,
 "OH": 	0.024	,
 "H2": 	0.0374	,
 "H2O": 	0.428	,
 "HO2": 	0.00000823	,
 "CO": 	0.0915	,
 "CO2": 	0.163	,
"C2H6": 	0.0118	,
 "C4H10": 	0.00007	,
 "C6H14":	0.0000466	,
"C6H12": 	0	,
 "C5H12": 	0	,
 "Butanol": 	0	,
 "iC5H12": 	0.0000233	,
 "iC4H8": 	0	,
 "2C4H8":	0	,
 "Cyclohexane": 	0	,
 "C3H3": 	0	,
},		
terminationTime=(0.05,'s'),		
)		
		
		
simpleReactor(		
    temperature=(2290,'K'),		
    pressure=(1.5,'atm'),		
    initialMoleFractions={		
"CH4": 	0.168	,
 "O2":	0.0125	,
 "AC3H4":	0.0000734	,
 "C3H8":	0.000495	,
"H": 	0.0121	,
 "O": 	0.00377	,
 "OH": 	0.0314	,
 "H2": 	0.0541	,
 "H2O": 	0.433	,
 "HO2": 	0.0000116	,
 "CO": 	0.122	,
 "CO2": 	0.146	,
"C2H6": 	0.00924	,
 "C4H10": 	0.000055	,
 "C6H14":	0.0000367	,
"C6H12": 	0	,
 "C5H12": 	0	,
 "Butanol": 	0	,
 "iC5H12": 	0.0000183	,
 "iC4H8": 	0	,
 "2C4H8":	0	,
 "Cyclohexane": 	0	,
 "C3H3": 	0	,
},		
terminationTime=(0.05,'s'),		
)		
		
		
		
simulator(		
    atol=1e-16,		
    rtol=1e-8,		
)		
		
model(		
    toleranceKeepInEdge=0.05,		
    toleranceMoveToCore=0.5,		
    toleranceInterruptSimulation=10^8,		
    maximumEdgeSpecies=100000		
)		

pressureDependence(		
    method='modified strong collision', # 'reservoir state'	
    maximumGrainSize=(1.0, 'kcal/mol'),		
    minimumNumberOfGrains=200,		
    temperatures=(290,3500,'K',8),		
    pressures=(0.02,100,'bar',5),		
    interpolation=('Chebyshev', 6, 4),		
    maximumAtoms=16,		
)
				
options(		
    units='si',		
    saveRestartPeriod=None,		
    saveSimulationProfiles=True,		
    generateOutputHTML=False,		
    generatePlots=True,		
)