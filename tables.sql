DROP TABLE Coup;
DROP TABLE CaseCarte;
DROP TABLE Partie;
DROP TABLE Carte;
DROP TABLE Joueur;
DROP TABLE Niveau;
DROP SEQUENCE sq_idjoueur;
DROP SEQUENCE sq_Npartie;
DROP SEQUENCE sq_Idcoup;
-------------------------------------------------------------------------------------------------------
--creation de sequence 
CREATE SEQUENCE sq_idjoueur START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE sq_Npartie START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE sq_Idcoup START WITH 1 INCREMENT BY 1;
-------------------------------------------------------------------------------------------------------
---creation de tables 
--TABLE Niveau
------------------------------------------------------------------------------------------------
CREATE TABLE Niveau(
NumNiveau NUMBER(10) CONSTRAINT pk_niveau PRIMARY KEY,
temps VARCHAR(30),
Taille_X VARCHAR(10) CONSTRAINT nn_Tatille_X NOT NULL,
Taille_Y VARCHAR(10) CONSTRAINT nn_Tatille_Y NOT NULL,
nb_click NUMBER, 
CONSTRAINT ck_niveau CHECK (NumNiveau IN (1,2,3))
);
-------------------------------------------------------------------------------------------------
-- TABLE Joueur
----------------------------------------------------------------------------------------------------
CREATE TABLE Joueur(
IdJoueur  NUMBER CONSTRAINT pk_joueur PRIMARY KEY,-- type qui s'auto-incremente PCA
MotDePasse VARCHAR(10) CONSTRAINT nn_mdp NOT NULL,--obliger l'utilisaruer d'avoir un mots de passe 
Mail VARCHAR(20) CONSTRAINT un_mail UNIQUE ,--obliger que l'adrsse mail soit unique 
Nom VARCHAR(20) ,
NumNiveau NUMBER(5) CONSTRAINT fk_niv_jeux REFERENCES Niveau(NumNiveau), -- le niveau max atteint par le joueur 
HEURBLOQUER VARCHAR(10),
JOURBLOQUER DATE
);

------------------------------------------------------------------------------------------------
--TABLE Partie
------------------------------------------------------------------------------------------------
CREATE TABLE Partie(
NPartie NUMBER ,-- type qui s'auto-incremente avec saisie manuelle possible si necessaire
HDebut VARCHAR(10),
HFin VARCHAR(10),
DateP DATE,
Score NUMBER(10),
Etat VARCHAR(10) CONSTRAINT ck_Etat CHECK(Etat IN (0,1)),--- 0 =perdu , 1= gagné
IdJoueur NUMBER CONSTRAINT fk_id_joueur REFERENCES Joueur(IdJoueur),
NumNiveau NUMBER(5) CONSTRAINT fk_nP_jeux REFERENCES Niveau(NumNiveau),
CONSTRAINT pk_partie PRIMARY KEY(NPartie,IdJoueur)
);
-------------------------------------------------------------------------------------------------
--TBALE Carte
-------------------------------------------------------------------------------------------------------
CREATE TABLE Carte(
NCarte NUMBER,
Image VARCHAR(100),
constraint pk_carte PRIMARY KEY (NCarte)
);
--------------------------------------------------------------------------------------------------------
--TABLE CaseCarte 
---------------------------------------------------------------------------------------------------
CREATE TABLE CaseCarte(
IdCase NUMBER ,
IdJoueur  NUMBER,
position_x VARCHAR(50) CONSTRAINT nn_x NOT NULL,
position_y VARCHAR(50) CONSTRAINT nn_y NOT NULL ,
NPartie NUMBER,
NCarte NUMBER,
constraint pk_CaseCarte PRIMARY KEY (IdCase,NPartie,IdJoueur),
constraint fk_partie foreign key (NPartie,IdJoueur) references Partie (NPartie,IdJoueur)  ON DELETE CASCADE,
constraint fk_Carte foreign key (NCarte) references Carte (NCarte)
);
------------------------------------------------------------------------------------------------------
--TABLE Coup
------------------------------------------------------------------------------------------------------
CREATE TABLE Coup(
IdCoup NUMBER ,
Ordre NUMBER,
HeurD VARCHAR(10),
HeurF VARCHAR(10),
IdCase NUMBER,
NPartie NUMBER,
IdJoueur NUMBER,
CONSTRAINT pk_Coup PRIMARY KEY (IdCoup),
CONSTRAINT fk_cases foreign key (idCase,NPartie,IdJoueur) references CaseCarte (idCase,NPartie,IdJoueur)
);
------------------------------------------------------------------------------------------------------
