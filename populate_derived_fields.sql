-- Restore ClinicalDetails from original
UPDATE CXRTable
SET ClinicalDetails = ClinicalDetailsOriginal;


-- =========================================
-- SECTION 1: Correct common spelling errors
-- =========================================
DECLARE @Corrections TABLE (
    Incorrect NVARCHAR(100),
    Correct NVARCHAR(100)
);

INSERT INTO @Corrections (Incorrect, Correct)
VALUES
    -- Cough variants
    ('cugh', 'cough'), ('choug', 'cough'), ('copugh', 'cough'), ('copgh', 'cough'),
    ('couhg', 'cough'), ('couph', 'cough'), ('cogh', 'cough'), ('coug ', 'cough'), ('coughh', 'cough'),

    -- Recurrent variants
    ('recurent', 'recurrent'), ('recurrenyt', 'recurrent'), ('reccurent', 'recurrent'),
    ('reccurentt', 'recurrent'), ('recurrant', 'recurrent'), ('recuring', 'recurring'),

    -- Breathlessness / SOB
    ('breathlesness', 'breathlessness'), ('breathlessnes', 'breathlessness'), ('sob', 'SOB'),
    ('shotness', 'shortness'), ('shortmess', 'shortness'),

    -- Haemoptysis variants
    ('hemoptysis', 'haemoptysis'), ('haemoptisis', 'haemoptysis'), ('haemoptesis', 'haemoptysis'),
    ('haemaptysis', 'haemoptysis'), ('heamoptysis', 'haemoptysis'), ('haemotpysis', 'haemoptysis'),

    -- Asthma
    ('asthama', 'asthma'), ('ashtma', 'asthma'), ('asthna', 'asthma'),

    -- Chest
    ('chset', 'chest'), ('chesst', 'chest'), ('chets', 'chest'),

    -- Pneumonia
    ('pneumania', 'pneumonia'), ('pnumonia', 'pneumonia'), ('pneumonnia', 'pneumonia'), ('newmonia', 'pneumonia'),

    -- LRTI & other
    (' RTI', ' LRTI'), ('ABX', 'antibiotics'), (' ae ', ' air entry '), ('sx', 'symptoms'),
    ('desopite', 'despite'), ('of ', ''), ('wieght', 'weight'), ('on going', 'ongoing'),
    ('ongoign', 'ongoing'), ('ifnection', 'infection'), ('copntiniued', 'continiued');

DECLARE @Incorrect NVARCHAR(100), @Correct NVARCHAR(100);
DECLARE CorrectionCursor CURSOR FOR SELECT Incorrect, Correct FROM @Corrections;
OPEN CorrectionCursor;
FETCH NEXT FROM CorrectionCursor INTO @Incorrect, @Correct;

WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE CXRTable
    SET ClinicalDetails = REPLACE(ClinicalDetails, @Incorrect, @Correct)
    WHERE ClinicalDetails LIKE '%' + @Incorrect + '%';
    FETCH NEXT FROM CorrectionCursor INTO @Incorrect, @Correct;
END
CLOSE CorrectionCursor;
DEALLOCATE CorrectionCursor;


-- =========================================
-- SECTION 2: Update symptom flags
-- =========================================
UPDATE CXRTable
SET
    Cough = CASE WHEN ClinicalDetails LIKE '%cough%' AND
                      ClinicalDetails NOT LIKE '%no cough%' AND
                      ClinicalDetails NOT LIKE '%no %, cough%' AND
                      ClinicalDetails NOT LIKE '%cough not%' AND
                      ClinicalDetails NOT LIKE '%not cough%' THEN 1 ELSE 0 END,

    Fatigue = CASE WHEN (ClinicalDetails LIKE '%fatigue%' OR ClinicalDetails LIKE '%tired%' OR
                         ClinicalDetails LIKE '%exhausted%' OR ClinicalDetails LIKE '%malaise%' OR
                         ClinicalDetails LIKE '%TATT%') AND
                         ClinicalDetails NOT LIKE '%no fatigue%' AND
                         ClinicalDetails NOT LIKE '%no tired%' AND
                         ClinicalDetails NOT LIKE '%no TATT%' AND
                         ClinicalDetails NOT LIKE '%not tired%' THEN 1 ELSE 0 END,

    ShortnessOfBreath = CASE WHEN (ClinicalDetails LIKE '%SOB%' OR ClinicalDetails LIKE '%breathless%' OR
                                   ClinicalDetails LIKE '%short of%' OR ClinicalDetails LIKE '%shortness%' OR
                                   ClinicalDetails LIKE '%dyspnoea%' OR ClinicalDetails LIKE '%stridor%' OR
                                   ClinicalDetails LIKE '%wheez%') AND
                                   ClinicalDetails NOT LIKE '%no SOB%' AND
                                   ClinicalDetails NOT LIKE '%not wheez%' THEN 1 ELSE 0 END,

    ChestPain = CASE WHEN (ClinicalDetails LIKE '%pain%' OR ClinicalDetails LIKE '%chest discomfort%' OR
                           ClinicalDetails LIKE '%CP%' OR ClinicalDetails LIKE '%pleurisy%' OR
                           ClinicalDetails LIKE '%pleuritic%' OR ClinicalDetails LIKE '%chest tightness%') AND
                           ClinicalDetails NOT LIKE '%no chest pain%' AND
                           ClinicalDetails NOT LIKE '%not pain%' THEN 1 ELSE 0 END,

    Haemoptysis = CASE WHEN (ClinicalDetails LIKE '%haemoptysis%' OR ClinicalDetails LIKE '%blood in sputum%' OR
                             ClinicalDetails LIKE '%coughing up blood%' OR ClinicalDetails LIKE '%expectorating blood%') AND
                             ClinicalDetails NOT LIKE '%no haemoptysis%' AND
                             ClinicalDetails NOT LIKE '%not haemoptysis%' THEN 1 ELSE 0 END,

    WeightLoss = CASE WHEN (ClinicalDetails LIKE '%weight%' OR ClinicalDetails LIKE '%cachexia%') AND
                          ClinicalDetails NOT LIKE '%weight gain%' AND
                          ClinicalDetails NOT LIKE '%no weight%' THEN 1 ELSE 0 END,

    AppetiteLoss = CASE WHEN (ClinicalDetails LIKE '%appetite%' OR ClinicalDetails LIKE '%anorex%') AND
                            ClinicalDetails NOT LIKE '%no appetite%' AND
                            ClinicalDetails NOT LIKE '%not appetite%' THEN 1 ELSE 0 END;


-- =========================================
-- SECTION 3: Clinical 5 criteria, smoker, cancer, and NG12symptoms count
-- =========================================
UPDATE CXRTable
SET Clinical5 = CASE WHEN ClinicalDetails LIKE '%recurrent chest infection%' OR
                          ClinicalDetails LIKE '%clubbing%' OR
                          ClinicalDetails LIKE '%thrombocytosis%' OR
                          ClinicalDetails LIKE '%cervical node%' THEN 1 ELSE 0 END;

UPDATE CXRTable
SET Smoker = CASE 
    WHEN ClinicalDetails LIKE '%ex smok%' THEN '3.Ex Smoker'
    WHEN ClinicalDetails LIKE '%current smok%' THEN '1.Current Smoker'
    WHEN ClinicalDetails LIKE '%smok%' THEN '2.Smoker (not specified)'
    WHEN ClinicalDetails LIKE '%passive smok%' THEN '4.Passive smoker'
    WHEN ClinicalDetails LIKE '%never smok%' THEN '6.Never smoked'
    ELSE '7.Unknown'
END;

UPDATE CXRTable
SET Cancer = CASE 
    WHEN ClinicalDetails LIKE '%cancer%' AND ClinicalDetails NOT LIKE '%no cancer%' THEN 'Yes'
    WHEN ClinicalDetails LIKE '%no cancer%' THEN 'No'
    ELSE 'Unknown'
END;

UPDATE CXRTable
SET NG12symptoms = Cough + Fatigue + ShortnessOfBreath + ChestPain + WeightLoss + AppetiteLoss;


-- =========================================
-- SECTION 4: NG12 A/B/C flags
-- =========================================
UPDATE CXRTable
SET NG12A = CASE WHEN Clinical5 = 1 THEN 1 ELSE 0 END;

UPDATE CXRTable
SET NG12B = CASE WHEN NG12symptoms >= 1 AND SmokingStatus LIKE '%Smoker%' THEN 1 ELSE 0 END;

UPDATE CXRTable
SET NG12C = CASE WHEN NG12symptoms >= 2 AND SmokingStatus NOT LIKE '%Smoker%' THEN 1 ELSE 0 END;


-- =========================================
-- SECTION 5: Assign cohorts for evaluation (optional)
-- =========================================
UPDATE CXRTable
SET Cohort = CASE 
    WHEN CaseNo < 242 THEN '1-241'
    WHEN CaseNo BETWEEN 242 AND 750 THEN '742-750'
    WHEN CaseNo BETWEEN 751 AND 1000 THEN '751-1000'
    ELSE '1001+'
END;


-- =========================================
-- SECTION 6: Test result and ground truth flags
-- =========================================
UPDATE CXRTable
SET TestPositive = CASE 
    WHEN Haemoptysis = 0 AND
         (
            NG12A = 1 OR 
            (NG12B = 1 AND LungCancerPossibility = 'Yes') OR 
            (NG12C = 1 AND LungCancerPossibility = 'Yes')
         ) THEN 1
    ELSE 0
END;

UPDATE CXRTable
SET GroundTruthPositive = CASE 
    WHEN Category LIKE '%(A)%' OR 
         (Category LIKE '%(B)%' AND LungCancerPossibility = 'Yes') OR 
         (Category LIKE '%(C)%' AND LungCancerPossibility = 'Yes') THEN 1
    ELSE 0
END;


-- =========================================
-- SECTION 7: Assign confusion matrix label
-- =========================================
UPDATE CXRTable
SET Matrix = CASE 
    WHEN TestPositive = 1 AND GroundTruthPositive = 1 THEN 'TP'
    WHEN TestPositive = 1 AND GroundTruthPositive = 0 THEN 'FP'
    WHEN TestPositive = 0 AND GroundTruthPositive = 1 THEN 'FN'
    ELSE 'TN'
END;
