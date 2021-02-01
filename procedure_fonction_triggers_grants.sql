---Creation de procedures 
-----------------------------------------------------------------------------------
SET SERVEROUTPUT ON;

begin
DBMS_OUTPUT.PUT_LINE('HELLO');
END; 
/
---Creation de la procedures insert_partie 
CREATE OR REPLACE PROCEDURE insert_partie(vMailJ Joueur.Mail%TYPE, 
                                         VNiveau Partie.NumNiveau%TYPE,vNPartie OUT NUMBER,retour OUT NUMBER) AS 
    
    Vhdebut Partie.HDebut%TYPE; 
    VIdjoueur Partie.IdJoueur%TYPE;
   
    idpartie NUMBER:=sq_Npartie.NEXTVAL;
    pb_clefetrangere EXCEPTION;
    PRAGMA EXCEPTION_INIT(pb_clefetrangere, -2291);
    --- exception quand le triggger est t_b__controlniveau est activé 
    niveau_non_autorise EXCEPTION;
    PRAGMA exception_init(niveau_non_autorise, -20000);
    ------ exception à lever losque le trigger T_B_I_CONTROLEPARTIE est activé
    TROP_DE_PARTIE_PERDU EXCEPTION;
    PRAGMA exception_init(TROP_DE_PARTIE_PERDU, -20001);
    
     BEGIN 
     ----Recuperer l'id du joueur à travers son mail
         SELECT IdJoueur INTO VIdjoueur
         FROM Joueur 
         WHERE Joueur.Mail = vMailJ;
         SELECT to_char(sysdate,'hh24:mi:ss') INTO Vhdebut FROM DUAL;
         INSERT INTO Partie(NPartie,HDebut,DateP,IdJoueur,NumNiveau)
         VALUES (idpartie,Vhdebut,sysdate,VIdjoueur,VNiveau);
         retour :=0;
         vNPartie:=idpartie;
         COMMIT;
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN --Quand la partie est dèjà jouée
            
            retour :=1;
            WHEN NO_DATA_FOUND THEN 
             
             retour :=2;
            WHEN pb_clefetrangere THEN
            IF(SQLERRM LIKE'%FK_ID_JOUEUR%') THEN -- Le joueur n'existe pas 
             
              retour :=3;
            ELSE --le niveau n'existe pas 
             
              retour :=4;
            END IF;
            WHEN niveau_non_autorise THEN 
            
             retour :=5;
            WHEN TROP_DE_PARTIE_PERDU THEN
             
             retour :=6;
            WHEN OTHERS THEN --autres problemes 
             
            retour :=7;
        
END;
/

-------------------------------------------------------------------------------------------------
-- Creation de procedure d'autentification 
--lors de la connexion, verifie si le joueur rentre bien le bon mot de passe pour le bon identifiant
CREATE OR REPLACE PROCEDURE authentification(vMailJ Joueur.Mail%type,vMotDePasse Joueur.MotDePasse%type,
                                             retour OUT NUMBER) AS
        tesMotDePasse Joueur.MotDePasse%type;
        
        erreurMotDePasse EXCEPTION;
        BEGIN  
            --selectionner le mot de passe du joueur 
            SELECT MotDePasse INTO tesMotDePasse
            FROM Joueur
            WHERE Mail = vMailJ;
           
                -- tester si le mot de passe correspond au mot de passe selectionner 
                IF (vMotDePasse != tesMotDePasse) THEN
                  RAISE erreurMotDePasse;
                END IF;
            retour :=0;
            COMMIT;
            EXCEPTION 
                WHEN  NO_DATA_FOUND THEN --si le mail n'existe pas
                retour :=1;
                
                WHEN erreurMotDePasse THEN --si le mot de passe ne correspond pas
                
                retour :=2; 
                WHEN OTHERS THEN -- si autre cas 
                
                retour :=3; 
END;
/

----------------------------------------------------------------------------------------------------------










----procédure inserer un utilisateur
CREATE OR REPLACE PROCEDURE Inserer_Joueur(vMailJ Joueur.Mail%type,vMotDePasse Joueur.MotDePasse%type,
                                           vNom Joueur.Nom%type, retour out number) AS

        vIdJoueur Joueur.IdJoueur%type;
        nb_ligne_mail NUMBER;
        pb_vniveau EXCEPTION;
        PRAGMA exception_init(pb_vniveau, -2291);
        pb_mdp EXCEPTION;
        pb_nullite_mail EXCEPTION ;
        pb_unicite_mail EXCEPTION;
        BEGIN   
            ---Recupere la valeur courante de la sequence,qui sera l'id du joueur
            SELECT sq_idjoueur.NEXTVAL INTO vIdJoueur FROM DUAL;
            --Recupere le nombre de ligne contenant vMailJ
            SELECT COUNT(*) INTO nb_ligne_mail
            FROM Joueur
            WHERE Joueur.Mail=vMailJ;
            
            --verifier si la mot de passe et le mail existent
            IF vMotDePasse IS NULL THEN
               RAISE pb_mdp;
            END IF;
            IF vMailJ IS NULL THEN 
              RAISE pb_nullite_mail;
            END IF;
            IF nb_ligne_mail>0 THEN 
              RAISE pb_unicite_mail ;
            END IF;
            INSERT INTO Joueur (IdJoueur,MotDePasse,Mail,Nom,NumNiveau) VALUES (vIdJoueur,vMotDePasse,vMailJ,vNom,1);
            retour:=0;
            COMMIT;
            
            EXCEPTION  
            WHEN  DUP_VAL_ON_INDEX THEN -- cet identifiant existe deja
            retour:=1;
            
            WHEN  pb_vniveau THEN -- ce niveau n'existe pas
            retour:=2;
            
            WHEN  pb_mdp THEN -- le mot de passe ne peux etre vide
            retour:=3;
           
            WHEN  pb_nullite_mail THEN -- le mail ne peux etre vide
            retour:=4;
            
            WHEN  pb_unicite_mail THEN -- le mail ne peux etre vide
            retour:=5;
            
            WHEN OTHERS THEN --si autre cas
            retour:=6;
            
END;
/
---------------------------------------------------------------------------------------------------------------



--procédure de fin de partie 
--update la partie avec Etat=GAGNE ou PERDU et l'heure de fin 
--update dans enregistre la derniere case, 
--augmente le niveau du joueur si la partie est gagné
--update la table Joueur augmenter le NiveauMax atteint 
CREATE OR REPLACE PROCEDURE partie_finie(vNPartie Partie.NPartie%type,vMailJ Joueur.Mail%TYPE,vEtat Partie.Etat%type,
        vOrdre Coup.Ordre%type, retour out number) AS
        
        vHeurFin Partie.HFin%type := to_char(sysdate,'hh24:mi:ss') ;
        vniveau Partie.NumNiveau%type;
        vheurdeb Partie.HDebut%TYPE;
        vScorePartie Partie.Score%TYPE;
        
        vdiff NUMBER;
        nbpartieperdu NUMBER:=0;
        transition NUMBER:=0;
        vdate DATE := sysdate();
        VIdjoueur Partie.IdJoueur%TYPE;
        
        pb_clefetrangere EXCEPTION;
        PRAGMA exception_init(pb_clefetrangere, -2291);
        pbpartie exception;
        
        PRAGMA exception_init(pbpartie, -20003);
        -- exeception à executer quand le triggers t_b_u_InsertionPartie est activé 
        -- quand aucun mouvement est arregisterer on suprime la partie

        
        BEGIN  
        
            retour:=0;
            --Recuperer l'id du joueur à partir du mail
            SELECT IdJoueur INTO VIdjoueur
            FROM Joueur 
            WHERE Joueur.Mail = vMailJ;
            
            select NumNiveau, HDebut into  vniveau,vheurdeb -- recupère le niveau et HDebut  de la partie 
            --à partir de l'NPartie
            from partie
            where NPartie = vNPartie AND IdJoueur=vIdJoueur;
           IF (vEtat = 0) THEN  -- si l'utilisateur a perdu la partie 
               vScorePartie:=0;
           ELSE  
                --on fait l'appelle de la  fonction calcule_score 
                SELECT calcule_score(vheurdeb,vHeurFin,vniveau) INTO vScorePartie FROM DUAL;
           END IF; 
            
            update partie -- met à jour la table partie  
            set HFin = vHeurFin ,
            Etat = vEtat, 
            Score =  vScorePartie
            where NPartie = vNPartie AND IdJoueur=vIdJoueur;
            --met à jour la derniere case joué
            update Coup 
            set HeurF = vHeurFin
            where Ordre= vOrdre
            and NPartie = vNPartie and IdJoueur=vIdJoueur;
            
            if (UPPER(vEtat) = 1 and vniveau < 3) then --on augmente le niveau du joueur au bout d'une partie gagne
                if vniveau = 1 then 
                    update joueur
                    set NumNiveau = 2
                    where IdJoueur = vIdJoueur; 
                else
                update joueur
                SET NumNiveau = 3
                WHERE IdJoueur = vIdJoueur;
                
                END IF;
            END IF;
            
        IF (vEtat = 0) THEN  -- on enregistre l'heure de sa dernière partie perdu

            IF  vHeurFin > '01:00:00' THEN -- si c'est plus d'une heure du matin
                SELECT COUNT(*) INTO nbpartieperdu
                FROM partie
                WHERE TRUNC(DateP) = TRUNC(vdate)
                AND diffTempsVarch(vHeurFin,partie.HFin) <= '01:00:00' 
                AND Etat = 0
                AND IdJoueur = vIdJoueur;
            
            ELSE  -- si c'est moins qu'1h du matin
                    SELECT COUNT(*) INTO nbpartieperdu
                    FROM partie
                    WHERE DateP = vdate 
                    AND HFin < vHeurFin
                    AND Etat = 0
                    AND Idjoueur = vIdJoueur;
                
                    SELECT COUNT(*) INTO transition 
                    FROM Partie
                    WHERE DateP = vdate-1 
                    AND diffTempsVarch(HFin,'24:00:00') <= diffTempsVarch('01:00:00',vHeurFin)
                    AND Etat = 0
                    AND IdJoueur = vIdJoueur;
                    nbpartieperdu := nbpartieperdu + transition;
                
            END IF;
                
            IF nbpartieperdu >=5 THEN
                UPDATE Joueur 
                SET Heurbloquer =vHeurFin,Jourbloquer =vdate
                WHERE IdJoueur =vIdJoueur;
            END IF;

     END IF;

            
     COMMIT;
            
            EXCEPTION  
            WHEN pb_clefetrangere THEN --joueur n'existe pas
            
            retour:=1;
            WHEN pbpartie THEN -- efface la partie si celle-ci n'a pas été joué, ie: aucun mouvement effectué
            DELETE Partie WHERE NPartie=vNPartie AND IdJoueur = vIdJoueur;
            COMMIT;
            
            retour := 2;
            WHEN NO_DATA_FOUND THEN -- si la partie n'existe pas 
            
            retour:= 3;
            WHEN OTHERS THEN --si autres problemes 
            
            retour:=4; 
END;
/
---------------------------------------------------------------------------------------------------------------------------------
















-- Procedure pour inserer une case 
CREATE OR REPLACE PROCEDURE inserer_case(vIdCase CaseCarte.IdCase%TYPE,vX CaseCarte.position_x%TYPE,vY CaseCarte.position_y%TYPE,
                                        vMailJ Joueur.Mail%TYPE,vNPartie CaseCarte.NPartie%TYPE,
                                         vNcarte CaseCarte.NCarte%TYPE, retour OUT NUMBER) AS
       
       VIdjoueur Partie.IdJoueur%TYPE;
       Pb_foreign_key EXCEPTION;
       PRAGMA EXCEPTION_INIT(Pb_foreign_key, -2291);
       pb_coordonnee EXCEPTION ;
       BEGIN 
            --Recuperer l'id du joueur à partir du mail
            SELECT IdJoueur INTO VIdjoueur
            FROM Joueur 
            WHERE Joueur.Mail = vMailJ;
            IF (vX IS NULL) OR (vY IS NULL) THEN
              RAISE pb_coordonnee;
            END IF;
            INSERT INTO CaseCarte VALUES (vIdCase,vIdJoueur,vX,vY,vNPartie,vNcarte);
            retour := 0;
            COMMIT;
            EXCEPTION 
               WHEN NO_DATA_FOUND THEN 
              
               retour := 1;
               WHEN DUP_VAL_ON_INDEX THEN -- case déjà insere
               
               retour := 2;
               WHEN Pb_foreign_key THEN 
               IF (SQLERRM LIKE '%FK_PARTIE%') THEN -- la partie n'existe pas 
                
                 retour := 3;
               ELSE -- si la carte n'existe pas
                 
                 retour := 4;
               END IF;
               WHEN   pb_coordonnee THEN -- un des coordonnées est NULL
               
               retour := 5;
               WHEN OTHERS THEN -- si autre cas 
                
                retour:=6;                                            
END;
/

------------------------------------------------------------------------------------------------------------------------------
--procedure pour gerer la table coup 
-- enregistrer l'ordre des mouvements des carte + l'heur à la quelle le joueur les a touché 
CREATE OR REPLACE PROCEDURE gerer_coup(vIdcase CaseCarte.IdCase%TYPE,vordrecoup Coup.Ordre%TYPE,vNPartie Partie.NPartie%TYPE,
                                       vMailJ Joueur.Mail%TYPE,retour OUT NUMBER ) AS 
                                       
   
   vheur Coup.HeurD%TYPE;
   vIdCoup Coup.IdCoup%TYPE;
   VIdjoueur Partie.IdJoueur%TYPE;
   pb_partie EXCEPTION;
   PRAGMA exception_init(pb_partie, -2291);
  
   BEGIN 
   
        --Recuperer l'id du joueur à partir du mail
        SELECT IdJoueur INTO VIdjoueur
        FROM Joueur 
        WHERE Joueur.Mail = vMailJ;

        -----selctipon la valeur suivante de IdCoup 
        SELECT sq_Idcoup.NEXTVAL INTO vIdCoup FROM DUAL;
        -- recuperer l'heur dy systeme
        SELECT to_char(sysdate,'hh24:mi:ss') INTO vheur FROM DUAL;  
       ---enregistrer les  coup correspondants 
        INSERT INTO Coup(IdCoup,Ordre,HeurD,IdCase,NPartie,IdJoueur) VALUES (vIdCoup,vordrecoup,vheur,vIdcase,vNPartie,VIdjoueur);
        -- on ajoute l'heuer de coup precedent
        IF(vordrecoup>1) THEN 
            UPDATE Coup cp SET cp.HeurF= vheur
            WHERE cp.Ordre = vordrecoup -1 AND cp.IdCoup=vIdCoup-1;
        END IF;
        retour :=0;
        COMMIT;
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN -- 
            
            retour :=1;
            WHEN DUP_VAL_ON_INDEX THEN  -- -- coup déjà inserer
            
            retour :=2;
            WHEN pb_partie THEN -- quand la partie n'existe pas
             
            retour := 3;
            WHEN OTHERS THEN
            
            retour := 4;

END;
/
-----------------------------------------------------------------------------------------------------------------------------
--procedure qui retourne l'id d'une carte à partie de l'identfiant 
CREATE OR REPLACE PROCEDURE recupere_image(Vimage Carte.Image%TYPE, idcart OUT Carte.NCarte%TYPE) AS 
     BEGIN 
       SELECT Carte.NCarte INTO idcart FROM Carte WHERE Carte.Image = Vimage;

END;
/

------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------
--Gestion Procedures pour les tables High scores 
--pour cela on a choisit l'utilissation des viewsSS
--Classement pour la journée en cours 

CREATE OR REPLACE VIEW ClassementJour as
    SELECT * 
    FROM (SELECT Mail, Score 
    FROM Partie p,Joueur j
    WHERE  TRUNC(p.DateP)=TRUNC(SYSDATE) AND p.IdJoueur=j.IdJoueur AND p.Score IS NOT NULL
    ORDER BY  Score desc)
    WHERE ROWNUM <= 5;
    

--Classement toujours 
--pour le niveau 1
CREATE OR REPLACE VIEW Classement_niv1 as
    SELECT * 
    FROM (SELECT Mail, Score 
    FROM Partie p,Joueur j
    WHERE p.NumNiveau=1 and p.IdJoueur=j.IdJoueur and p.Score IS NOT NULL
    ORDER BY Score desc)
    WHERE ROWNUM <= 5;
--pour le niveau 2
CREATE OR REPLACE VIEW Classement_niv2 as
    SELECT * 
    FROM (SELECT Mail, Score 
    FROM Partie p,Joueur j
    WHERE p.NumNiveau=2 and p.IdJoueur=j.IdJoueur and p.Score IS NOT NULL
    ORDER BY Score desc)
    WHERE ROWNUM <= 5;
--pour le niveau 3   
CREATE OR REPLACE VIEW Classement_niv3 as
    SELECT * 
    FROM (SELECT Mail, Score 
    FROM Partie p,Joueur j
    WHERE p.NumNiveau=3 and p.IdJoueur=j.IdJoueur and p.Score IS NOT NULL
    ORDER BY Score desc)
    WHERE ROWNUM <= 5;


--------------------------------------------------------------------------------------------------------------------------------
--Creation de Triggers 
---Triggers empêchant une partie de se jouer 
CREATE OR REPLACE TRIGGER t_b_i_controleNiveau 
BEFORE INSERT ON Partie 
FOR EACH ROW
DECLARE
niveauMax NUMBER;

BEGIN
SELECT NumNiveau INTO niveauMax FROM Joueur WHERE Joueur.IdJoueur =:NEW.IdJoueur;

IF (:NEW.NumNiveau >  niveauMax) THEN
    raise_application_error(-20000,'Niveau pas autorisé');
    
END IF;
END;
/

--- Trigger permetteant de gèrer le nombre de partie perdu 
-- verifie que le joueur n'a pas perdu 5 partie dans l'heure 

CREATE OR REPLACE TRIGGER t_b_i_controlePartie
BEFORE
INSERT ON PARTIE
FOR EACH ROW

DECLARE
vdate DATE := sysdate;
vHeure VARCHAR2(10) := TO_CHAR(SYSDATE,'hh24:mi:ss') ;
vheurebloquer Joueur.HEURBLOQUER%type;
vjourbloquer Joueur.JOURBLOQUER%type;

BEGIN

SELECT HEURBLOQUER,JOURBLOQUER INTO vheurebloquer,vjourbloquer
FROM JOUEUR
WHERE IdJoueur = :NEW.IdJoueur;

IF (TRUNC(vdate) = TRUNC(vjourbloquer) AND diffTempsVarch(vHeure,vheurebloquer) <= '04:00:00') THEN 
raise_application_error(-20001, 'trop de partie perdu');

END IF;

END;
/

-- efface la partie ci celle ci n'a pas été joué, ie: pas de mouvement 

CREATE OR REPLACE TRIGGER t_b_u_InsertionPartie
BEFORE UPDATE ON partie
FOR EACH ROW

DECLARE
nbmvt NUMBER;
vIdCase CaseCarte.IdCase%TYPE;
BEGIN



IF :NEW.Etat = 0 THEN 
  
    SELECT COUNT(IdCoup) INTO nbmvt --compte le nombre de coup joué dans la partie
    FROM Coup 
    WHERE NPartie=:NEW.NPartie AND IdJoueur=:NEW.IdJoueur;
    
    IF nbmvt =0 THEN
        raise_application_error(-20003, 'partie a enleve');
    END IF;


END IF;

END;
/

-----------------------------------------------------------------------------------------------------------------






--craetion de grants 
--sur les tables
GRANT SELECT ON DLT1940A.Niveau TO bns2057a;
GRANT SELECT ON DLT1940A.Carte TO bns2057a;
GRANT SELECT ON DLT1940A.Partie TO bns2057a;
GRANT SELECT ON DLT1940A.Joueur TO bns2057a;
GRANT SELECT ON DLT1940A.CaseCarte TO bns2057a;
GRANT SELECT ON DLT1940A.Coup TO bns2057a;

--sur les views
GRANT SELECT ON DLT1940A.ClassementJour TO bns2057a;
GRANT SELECT ON DLT1940A.Classement_niv1 TO bns2057a;
GRANT SELECT ON DLT1940A.Classement_niv2 TO bns2057a;
GRANT SELECT ON DLT1940A.Classement_niv3 TO bns2057a;

--- sur les procedures

GRANT EXECUTE ON DLT1940A.authentification TO bns2057a;
GRANT EXECUTE ON DLT1940A.Inserer_Joueur TO bns2057a;
GRANT EXECUTE ON DLT1940A.insert_partie TO bns2057a;
GRANT EXECUTE ON DLT1940A.recupere_image TO bns2057a;
GRANT EXECUTE ON DLT1940A.inserer_case TO bns2057a;
GRANT EXECUTE ON DLT1940A.gerer_coup TO bns2057a;
GRANT EXECUTE ON DLT1940A.partie_finie TO bns2057a;

COMMIT;


---------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-----Founctions 
----- Fonctions por convertir le temps entré en parametre en seconde 
CREATE OR REPLACE FUNCTION calcule_en_seconde (vHeurD VARCHAR2) RETURN NUMBER AS 
     
    time_in_second NUMBER;
    
    BEGIN
    SELECT SUBSTR(vHeurD, 1, 2)*3600 + SUBSTR(vHeurD, 4, 2)*60 + SUBSTR(vHeurD, 7, 2) INTO time_in_second
    FROM dual;
    
    RETURN (time_in_second);

END;
/
-------------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------------
---fonction qui calcul la difference entre deux heurs(en format HH24:min:ss) passsées en paramtre
--retourn un number  

CREATE OR REPLACE FUNCTION diffTempsNumber( HeurF in varchar2, HeurD in varchar2) RETURN NUMBER IS

        vHDebut VARCHAR(10);
        vHFin VARCHAR(10);
        dif_temps NUMBER; 
        
BEGIN
        SELECT SUBSTR(HeurD, 1, 2)*3600 + SUBSTR(HeurD, 4, 2)*60 + SUBSTR(HeurD, 7, 2) INTO vHDebut
        FROM DUAL;
        
        SELECT SUBSTR(HeurF, 1, 2)*3600 + SUBSTR(HeurF, 4, 2)*60 + SUBSTR(HeurF, 7, 2) INTO vHFin
        FROM DUAL;
        
        dif_temps := vHFin - vHDebut;
        
        
        RETURN(dif_temps);
END;
/

-------------------------------------------------------------------------------------------------------------------------
-- convertir un temps en format heur HH24:min:ss (varchar)
CREATE OR REPLACE FUNCTION diffTempsVarch ( HeurF in varchar2, HeurD in varchar2) RETURN VARCHAR2 IS
        
        vheuredeb varchar2(10);
        vheurefin varchar2(10);
        difference varchar2(10); 

BEGIN
            SELECT SUBSTR(HeurD, 1, 2)*3600 + SUBSTR(HeurD, 4, 2)*60 + SUBSTR(HeurD, 7, 2) INTO vheuredeb
            FROM DUAL;
            
            SELECT SUBSTR(HeurF, 1, 2)*3600 + SUBSTR(HeurF, 4, 2)*60 + SUBSTR(HeurF, 7, 2) INTO vheurefin
            FROM DUAL;
        

        
        SELECT TO_CHAR(TO_DATE(vheurefin - vheuredeb,'SSSSS'),'HH24:mi:ss') INTO difference FROM DUAL;
        RETURN difference;

END;
/
--------------------------------------------------------------------------------------------------------------
--fonction qui calcule le score en fonction du nievau

CREATE OR REPLACE FUNCTION calcule_score (vHeurD VARCHAR2, vHeurF VARCHAR2, vniveau number) RETURN NUMBER IS

        
        score NUMBER;
        vtemps niveau.temps%TYPE;
        coef NUMBER;
        
BEGIN
        SELECT temps INTO vtemps
        FROM niveau 
        WHERE NumNiveau = vniveau;
        
        CASE (vniveau)
             WHEN 1 THEN coef :=1;
             WHEN 2 THEN coef :=1.5;
             WHEN 3 THEN coef :=2;
             ELSE coef :=0;
        END CASE;
        
        score := (vtemps - diffTempsNumber ( vHeurF, vHeurD ));
        
        IF score <0 THEN
           score := 0;
        ELSE 
           score :=(diffTempsNumber( vHeurF, vHeurD ))*100*coef/vtemps;
        END IF;
        RETURN(score);
END;
/
--------------------------------------------------
