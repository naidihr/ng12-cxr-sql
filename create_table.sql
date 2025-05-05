CREATE TABLE [dbo].[CXRTable](
    [CaseNo] INT NULL, -- Sequential unique identifier for each CXR request to be evaluated
    [ClinicalDetails] NVARCHAR(MAX) NULL, -- Unstructured: Free-text clinical indication from the CXR request
    [SmokingStatus] NVARCHAR(50) NULL, -- Structured: 'Current smoker', 'Ex-smoker', 'Never smoked'
    [LungCancerPossibility] NVARCHAR(50) NULL, -- Structured: 'Yes', 'No'
    [Category] NVARCHAR(200) NULL, 
    -- Expert-assigned classification. Definitions:
    --  1: Lung cancer possible - follow-up imaging
    --  2: Lung cancer possible - haemoptysis
    --  3: Lung cancer possible - NG-12 (A)
    --  4: Lung cancer possible - NG-12 (B)
    --  5: Lung cancer possible - current or ex-smoker - no NG-12 symptoms
    --  6: Lung cancer possible - never smoker - no NG-12 symptoms
    --  7: Lung cancer possible - NG-12 (C)
    --  8: Lung cancer not suspected - follow-up imaging
    --  9: Lung cancer not suspected - haemoptysis
    -- 10: Lung cancer not suspected - possible NG-12 (A)
    -- 11: Lung cancer not suspected - possible NG-12 (B)
    -- 12: Lung cancer not suspected - current or ex-smoker - no NG-12 symptoms
    -- 13: Lung cancer not suspected - never smoker - no NG-12 symptoms
    -- 14: Lung cancer not suspected - possible NG-12 (C)
    -- 15: Other

    -- Derived NG12 symptom flags (binary)
    [Cough] INT NULL,
    [Fatigue] INT NULL,
    [ShortnessOfBreath] INT NULL,
    [ChestPain] INT NULL,
    [WeightLoss] INT NULL,
    [AppetiteLoss] INT NULL,
    [Haemoptysis] INT NULL,

    -- Additional derived logic fields
    [Smoker] NVARCHAR(30) NULL, -- Derived from ClinicalDetails (not used in NG12 classification)
    [Cancer] NVARCHAR(10) NULL, -- Derived from ClinicalDetails (not used in NG12 classification)
    [NG12symptoms] INT NULL, -- Count of 6 symptoms
    [Clinical5] INT NULL, -- Presence of any "5 criteria" features
    [NG12A] INT NULL, -- Meets NG12 A: '5 criteria'
    [NG12B] INT NULL, -- Meets NG12 B: ≥1 of 6 symptoms in smoker
    [NG12C] INT NULL, -- Meets NG12 C: ≥2 of 6 symptoms in never smoker

    -- Metadata and free text
    [Cohort] NVARCHAR(10) NULL, -- Optional: label to define study cohorts for testing/validation
    [Matrix] NVARCHAR(10) NULL, -- TP/FP/TN/FN: classification against ground truth
    [ClinicalDetailsOriginal] NVARCHAR(MAX) NULL, -- Original unedited text

    -- Test evaluation flags
    [TestPositive] BIT NULL, -- Algorithm result
    [GroundTruthPositive] BIT NULL -- Expert label
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
