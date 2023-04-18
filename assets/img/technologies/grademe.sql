--Serena Zachariah

CREATE SEQUENCE seqGames;

CREATE OR REPLACE PROCEDURE procInsertGame (IN paramP1 CHAR(16), IN paramP2 CHAR(16), INOUT paramErrLvl SMALLINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $GO$
BEGIN
    -- Set default error level to 0
    paramErrLvl := 0;

    -- Swap parameters if p1>p2
    IF paramP1 > paramP2 THEN
        SELECT paramP1, paramP2 INTO paramP2, paramP1;
    END IF;
    -- Good!  Side-steps many problems!!!




    -- Check for error code 1: p1_id = p2_id
    IF paramP1 = paramP2 THEN
        paramErrLvl := 1;

    -- Check for error code 2: Either parameter is NULL or LENGTH(px_id)=0
    ELSIF paramP1 IS NULL OR LENGTH(paramP1) = 0 OR paramP2 IS NULL OR LENGTH(paramP2) = 0 THEN
        paramErrLvl := 2;

    -- Check for error code 3: Duplicate pair already exists
    ELSIF EXISTS (SELECT * FROM tblGames WHERE p1_id = paramP1 AND p2_id = paramP2) THEN
        paramErrLvl := 3;

    -- Check for error code 4: Either p1_id or p2_id not in tblPlayers
    ELSIF NOT EXISTS (SELECT * FROM tblPlayers WHERE p_id = paramP1) OR NOT EXISTS (SELECT * FROM tblPlayers WHERE p_id = paramP2) THEN
        paramErrLvl := 4;

    -- Insert the record if there are no errors
    ELSE
        INSERT INTO tblGames(g_id, p1_id, p2_id)
        VALUES(NEXTVAL('seqGames'), paramP1, paramP2);
    END IF;

    -- Log errors in tblErrata and set error level to -13
    IF paramErrLvl <> 0 THEN
        INSERT INTO tblErrata(e_id, e_doc, e_msg)
        VALUES(NEXTVAL('seqErrata'), CURRENT_DATE, CONCAT('Error Code ', paramErrLvl));
        paramErrLvl := -13;
    END IF;
END $GO$;

GRANT EXECUTE ON PROCEDURE procInsertGame TO public_Users;


-- Test code

-- One test case is inadequate.  Testing is 50% of the grade!
DO $GO$
DECLARE
    lvErrLvl SMALLINT;
BEGIN
    CALL procInsertGame('Al', 'Bob', lvErrLvl);
    RAISE NOTICE 'Procedure terminated; error level = %', lvErrLvl;
END $GO$;

