#!/usr/bin/env python
# -*- coding: utf-8 -*-

from sqlalchemy import create_engine
import numpy as np # utliser  pour la generation aleatoire de cartes 
import cx_Oracle
import datetime

from flask import Flask, render_template, Markup, request, session, redirect, url_for
# connecting to the database 
engine = create_engine('oracle://......@telline.univ-tlse3.fr:1521/etupre')
app = Flask(__name__)
################################################
## On crée une classe qu'on appelle Tile qui va contenir en x l'abscise de l'image et en y l'ordonnée de l'image, et en face l'adresse de l'image 

class Tile():
    def __init__(self, x,y,face):
        self.x = x
        self.y = y
        self.face = face # constructeur de la classe 
    def abs_x(self):
        return self.x # permet de recuperer l'abscisse
    def ord_y(self):
        return self.y # permet de recuperer l'ordonné
    def adr_face(self):
        return self.face # permet de recupperer l'adresse de l'image 
##########################################################################
# route for loging
@app.route("/", methods=['GET', 'POST'])
def index():
    
    if not session.get('logged_in'):
        return render_template('login.html')
    else:
        return render_template('home.html', message = 'wellcome!')

# if the user filled the form, direct him to the page 'home.html'
@app.route("/post_login", methods=['GET', 'POST'])
def login():
    
    if session.get('logged_in'):
        return redirect(url_for('index'))
    # declaring an error variable to print if somthing goes wrong
    # Check if "username" and "password" POST requests exist (user submitted form)

    if request.method == 'POST' and 'mail' in request.form and 'password' in request.form:
        # Create variables for easy access
        mail = request.form['mail']
        password = request.form['password']
        
        connection = engine.raw_connection()
        # Check if account exists 
        try:
            cursor = connection.cursor()
            a = cursor.var(cx_Oracle.NUMBER) # variable OUT
            cursor.callproc("DLT1940A.authentification", [mail,password,a])
            if (a.values[0]==1):
                error="Cet utilisateur n'existe pas"
                return render_template('login.html', msg = error)
            elif(a.values[0]==2):
                error="Mot de passe incorrect"
                return render_template('login.html', msg = error)
            elif(a.values[0]==3):
                error="Il y'a un problème lié au server revenez plutard"
                return render_template('login.html', msg = error)
            cursor.close()
            connection.commit()
        finally:
            connection.close()
        session['logged_in'] = True
        
        # enregistrer le mai dans la session 
        session['mail']=mail
        if session.get('logged_in'):
            return redirect(url_for('index'))
        else:
            return render_template('login.html',
 msg='Mot de passe incorrect')
    return render_template('login.html')
# route pour deconnexion
@app.route("/logout", methods=['GET', 'POST'])
def logout():
    # remove the username from the session if it's there

    session.pop('username', None)

    session.pop('logged_in', None)

    session.pop('password', None)
    return render_template('login.html', msg = "Vous êtes deconnecté avec succés")

# route pour inscription
@app.route('/register', methods=['GET', 'POST'])

def register():
    
    
     # Check if "username", "password" and "email" POST requests exist (user submitted form)
    if request.method == 'POST' and 'mail' in request.form and 'username' in request.form and 'password' in request.form:
        # Create variables for easy access
        username = request.form['username']
        password = request.form['password']
        mail = request.form['mail']
        connection = engine.raw_connection()
        # Check if account exists 
        try:
            cursor = connection.cursor()
            a = cursor.var(cx_Oracle.NUMBER) # variable OUT
            cursor.callproc("DLT1940A.Inserer_Joueur", [mail,password,username,a])
            if (a.values[0]==1):
                error="Cet utilisateur existe dèjà"
                return render_template('register.html', msg = error)
            elif(a.values[0]==2):
                error="Niveau inexistant"
                return render_template('register.html', msg = error)
            elif(a.values[0]==3):
                error="Le mot de passe ne peut pas être vide"
                return render_template('register.html', msg = error)
            elif(a.values[0]==4):
                error="L'adresse mail ne peut être vide"
                return render_template('register.html', msg = error)
            elif(a.values[0]==5):
                error="Cet mail est dèjà utilisé par autre utlisateur, veillez choisr un autre"
                return render_template('register.html', msg = error)
            elif(a.values[0]==6):
                error="Il y'a un autre probleme lié au server revenez plutard"
                return render_template('register.html', msg = error)
            cursor.close()
            connection.commit()
        finally:
            connection.close()
        session['logged_in'] = True
        
        # enregistrer le mai dans la session 
        session['mail']=mail
        print('utilis',session['mail'])
        if session.get('logged_in'):
            return render_template('home.html' , message = "wellcome!")
        else:
            return render_template('register.html',
 msg='Incorrect password')
    return render_template('register.html')

  




# route pour jouer 

@app.route('/jouer', methods=['GET', 'POST'])

def jouer():
    
    # on recupere le mail de l'utlisateur stockée dans la session
    mail = session['mail']  # mail de l'utilisateur
    print("user qui joue est",mail)
    
    # on recupere le niveau choisi par l'utlisateur
    idNiveau =request.args.get('id')
    print("le nombre est", idNiveau)
    # on insère dans la table partie avec la procédure stockée pour créer une nouvelle partie 
    
    connection = engine.raw_connection()
    try:
        cursor = connection.cursor()
        a = cursor.var(cx_Oracle.NUMBER) # variable OUT
        numP = cursor.var(cx_Oracle.NUMBER) # variable OUT du nParite
        cursor.callproc("DLT1940A.insert_partie", [mail,idNiveau,numP,a])
        if (a.values[0]==1):
            error="cette partie est dèjà joué"
            return render_template('home.html', msg = error)
        elif(a.values[0]==2):
            error="cet joueur n'existe pas"
            return render_template('home.html', msg = error)
        elif(a.values[0]==3):
            error="cet joueur n'existe pas"
            return render_template('home.html', msg = error)
        elif(a.values[0]==4):
            error="ce niveau n'existe pas"
            return render_template('home.html', msg = error)
        elif(a.values[0]==5):
            error="vous ne pouvez pas accerder à niveau superieur avant de valider le niveau en cour, merci!"
            return render_template('home.html', msg = error)
        elif(a.values[0]==6):
            error="vous avez perdu trop de parties vous serrez boqué pendant 4 heurs!"
            return render_template('home.html', msg = error)
        elif(a.values[0]==7):
            error="Il y'a un autre probleme lié au server revenez plutard"
            return render_template('home.html', msg = error)
        
        cursor.close()
        connection.commit()
    finally:
        connection.close()
        
    # recupere l'id de la partie en cours 
    
    id_partie=numP.values[0]
    
    # cette condition if concerne l'application du trigger t_b_u_InsertionPartie definie dans la base 
    # si l'utilisateur actualise la page la patie sera enregistrer sans qu'un coup ne soit fait, on recupere id_partie-1
    if (id_partie>1):# s'il a joué au moins une partie
        with engine.connect() as con:
            rs = con.execute('SELECT COUNT(IdCoup) FROM DLT1940A.Coup cp, DLT1940A.Joueur j WHERE cp.IdJoueur=j.IdJoueur AND j.Mail=\''+str(mail)+'\' AND cp.NPartie='+str(id_partie-1))
            for row in rs:
                nbcoup=row[0] # on recuper le nombre de coup
        if (nbcoup==0):
            # on fait l'appelle de la procedure partie_finie pour mettre à jour la base
            connection = engine.raw_connection()
            try:
                cursor = connection.cursor()
                a = cursor.var(cx_Oracle.NUMBER) # variable OUT
                cursor.callproc("DLT1940A.partie_finie", [id_partie-1,mail,0,1,a]) # on met n'import quelle valeur de ordre , on met etat à 0 pour declancher le trigger
                if(a.values[0]==4):
                    error="Il y'a un autre probleme lié au server revenez plutard"
                    return render_template('jouer.html', msg = error)
                cursor.close()
                connection.commit()
            finally:
                connection.close()
            print('la partie de id',id_partie-1,'est enlèvé')
            
        
    
    print('la partie en cours',id_partie)
        
    # on recupere le nombre de click maximum attribué au niveau
    req_nbclick = "select nb_click from DLT1940A.Niveau where NumNiveau ="+str(idNiveau)
    
    with engine.connect() as con:
      rs = con.execute(req_nbclick)
      for row in rs:
          nb_clik_max = row[0]
    print('nb_click',nb_clik_max)
    
    # recuperer la taille de la grille 
    grille = "select TAILLE_X,TAILLE_Y from DLT1940A.Niveau where NumNiveau ="+str(idNiveau)
    with engine.connect() as con:
      taille_grille  = con.execute(grille)
      for row in taille_grille:
          taille_x=str(row[0])
          print(taille_x)
          taille_Y=str(row[1])
          print(taille_Y)
    
    # on recupere les adresse des carte stokées dans la bd, et on les met dans la liste cartes
    cartes = []
    with engine.connect() as con:
      requet = con.execute("select Image from DLT1940A.carte")
      i= 0 # pour indexer les elements de row
      for row in requet:
          if i<10:
              if len(cartes)<int(taille_x)*int(taille_Y):
                  cartes.append(row[0])
                  cartes.append(row[0]) # ajouter deux fois la meme carte 
                  i+=1
    print(cartes)
    
    
    tailtab = len(cartes) # taille du tableau contenant les cartes
    col = tailtab/ 2 # nombre de colonne 
    cart_mlg = [] # nouveau tableau étant un mélange des élements du tableau qui contient les adresses des images
    
    while len(cart_mlg)<tailtab: # tant que cart_mlg n'a pas le meme nombre d'elemet que cartes faire 
        for i in range(tailtab):
            randomInd=np.random.randint(tailtab)
            face = cartes[randomInd]
            if cart_mlg.count(face)<2:# faire cette condition pour ne pas prendre un element plus de 2 fois
                cart_mlg.append(face)
    print(cart_mlg)
                
    tiles=[] # nouveau tableau contenant les adresses du tableau melangé crée avec le constructeur de la classe Tile definie en haut
    num_lign =int(taille_x)
    num_col = int(taille_Y)#  permettent d'attribuer un abscisse et une ordonnée aux élément de tiles
    k = 0
    for i in range(num_lign):
        for j in range(num_col):
            a = Tile(i,j,cart_mlg[k])
            tiles.append(a)
            k+=1
    idem = [] #tableau qui va contenir les identifiants des images dans leur ordre dans le tableau tiles
    
    pos = []# tableau qui va contenir les identifiants positions lorsqu'on mettra ces cartes dans la table casecarte
    print("nombred de tile",k)
    
    for i in range(k):
        q = tiles[i]
        face_carte = q.adr_face()
        connection = engine.raw_connection()
        try:
            cursor = connection.cursor()
            a = cursor.var(cx_Oracle.NUMBER) # variable OUT
            cursor.callproc("DLT1940A.recupere_image", [face_carte,a])
            cursor.close()
            connection.commit()
        finally:
            connection.close()
        idem.append(a.values[0])
    test = "ok"
    for i in range(k):
        q = tiles[i]
        abs_x = q.abs_x() # recupere l'ordonnée de l'abscisse 
        ord_y = q.ord_y() # recupere l'ordonnée de l'image
        id_carte = idem[i] # recupere l'id de la i eme carte
        # on insère dans la table casecarte de la bd
        connection = engine.raw_connection()
        try:
            cursor = connection.cursor()
            a = cursor.var(cx_Oracle.NUMBER) # variable OUT
            cursor.callproc("DLT1940A.inserer_case", [i,abs_x,ord_y,mail,id_partie,id_carte,a])
            if (a.values[0]==1):
                error="cet utilisateur n'existe pas"
                return render_template('home.html', msg = error)
            elif(a.values[0]==2):
                error="case déjà inseré"
                return render_template('home.html', msg = error)
            elif(a.values[0]==3):
                error="cette partie n'exiete pas pour inserer la case"
                return render_template('home.html', msg = error)
            elif(a.values[0]==4):
                error="Cette carte n'existe pas"
                return render_template('home.html', msg = error)
            elif(a.values[0]==5):
                error="l'un des coordonnées est null"
                return render_template('home.html', msg = error)
            elif(a.values[0]==6):
                error="Il y'a un autre probleme lié au server revenez plutard"
                return render_template('home.html', msg = error)
            cursor.close()
            connection.commit()
        finally:
            connection.close()
            
    # on transmet la taille du tableau contenant les cartes, l'identifiant de l'utilisateur, l'identifiant de la partie ainsi que le nombre de click maximums au fichier javascript
    code_html ="<script language=\"JavaScript\" type=\"text/javascript\"> var maVar = \""+str(tailtab)+"\"; var iduser = \"" +str(mail)+"\"; var idpartie = "+str(id_partie)+"; var nbClick = "+str(nb_clik_max)+"; var id_parie ="+str(id_partie)+"; var idNiveau ="+str(idNiveau)+";</script>"
    # on affiche les cartes renversées 
    for i in range(k):
        q = tiles[i]
        p = q.adr_face()
        pos = i
        # l'adresse de l'image p ainsi que l'identifiant de la position (pos) serviront a changer la face de la carte avec la fonction javascript ChangeImag
        code_html+= "<div class = \"memory-card\"> <img class =\"front-face\" id =\""+str(pos)+"\" src = \"static/Images/lune.jpg\" onClick=\"ChangeImage(\'"+str(p)+"\',\'"+str(pos)+"\')\" /> </div>"
    
    return render_template('jouer.html',content=Markup(code_html))




# route pour inserer les coup de la base 

@app.route('/inserer_coup', methods=['GET', 'POST'])

def inser_coup():
    # on recupere le mail de l'utlisateur stockée dans la session
    mail = session['mail']  # mail de l'utilisateur
    print("user qui joue est",mail)
    
    # on recupere les données envoyé par ajax, 
    # on recuperer l'id de la partie en cour
    id_partie=request.args.get('idpartie')
    
    # on recupere l'id de la case et l'ordre du clique envoyé 
    
    id_case=request.args.get('id_case')
    odrecoup=request.args.get('ordre')
    print('la case cliqué est',id_case)
    print('ordre coup',odrecoup)
    
    # on fait l'appelle de la procedure gere_coup pour inserer le clique dan la base
    connection = engine.raw_connection()
    try:
        cursor = connection.cursor()
        a = cursor.var(cx_Oracle.NUMBER) # variable OUT
        cursor.callproc("DLT1940A.gerer_coup", [id_case,odrecoup,id_partie,mail,a])
        if (a.values[0]==1):
            error="cet utilisateur n'existe pas"
            return render_template('jouer.html', msg = error)
        elif(a.values[0]==2):
            error="coup déjà inseré"
        elif(a.values[0]==3):
            error="la partie et la case n existent pas "    
            return render_template('jouer.html', msg = error)
        elif(a.values[0]==4):
            error="Il y'a un autre probleme lié au server revenez plutard"
            return render_template('jouer.html', msg = error)
        cursor.close()
        connection.commit()
    finally:
        connection.close()
    return render_template('jouer.html',message='ok')


# route pour une partie partie_finie
@app.route('/fin_partie', methods=['GET', 'POST'])

def partie_finie():
    
    # on recupere le mail de l'utlisateur stockée dans la session
    mail = session['mail']  # mail de l'utilisateur
    print("user qui joue est",mail)
    
    # on recupere les données envoyé par ajax, 
    # on recuperer l'id de la partie en cour
    idpartie=request.args.get('idpartie')
    
    etat_partie=request.args.get('etat') # etat_partie = 0 perdu,ou etat_partie=1 gagné
    odrecoup=request.args.get('ordre') # le dernier coup saisie
    print('id de la partie est',idpartie)
    print('gagné est',etat_partie)
    print('ordre dernier coup',odrecoup)
    
     # on fait l'appelle de la procedure partie_finie pour mettre à jour la base
    connection = engine.raw_connection()
    try:
        cursor = connection.cursor()
        a = cursor.var(cx_Oracle.NUMBER) # variable OUT
        cursor.callproc("DLT1940A.partie_finie", [idpartie,mail,etat_partie,odrecoup,a])
        if (a.values[0]==1):
            error="cet utilisateur n'existe pas"
            return render_template('jouer.html', msg = error)
        elif(a.values[0]==2):
            error="aucun mouvement detecté la partie est enlèvé"
            return render_template('jouer.html', msg = error)
        elif(a.values[0]==3):
            error="la partie nexiste pas"
            return render_template('jouer.html', msg = error)
        elif(a.values[0]==4):
            error="Il y'a un autre probleme lié au server revenez plutard"
            return render_template('jouer.html', msg = error)
        cursor.close()
        connection.commit()
    finally:
        connection.close()
    return render_template('jouer.html',message='ok')



# founction qui permet de recuperer la liste des partie jouées 

def mes_parties():
    mail = session['mail']  # mail de l'utilisateur
    print("user qui joue est",mail)
    
    listes_parties=[]
    print("mes parties jouées")
    with engine.connect() as con:
      rs  = con.execute('select distinct p.NPARTIE,p.DATEP,p.SCORE,p.ETAT,p.NUMNIVEAU from DLT1940A.PARTIE p, DLT1940A.JOUEUR j WHERE j.IDJOUEUR= p.IDJOUEUR and j.Mail= \'' + mail + '\'  order by (p.NPARTIE) DESC')
      for row in rs:
          listes_parties.append([row[0],row[1],row[2],row[3],row[4]])
    return listes_parties


# route qui permet de recuperer l'ensemble des parties jouées par l'utlisateur connecté

@app.route('/historique', methods=['GET', 'POST'])

def historique_des_partiess():
    liste_parties= mes_parties()
    code_html = "<table>"
    
    for elt in liste_parties:
       code_html+="<tr class='rejouer'> <td> <button type =\"button\" class='statu-"+str(elt[3])+"' onClick=\"rejouerPartie("+str(elt[0])+")\">Partie joué le  "+str(elt[1])+  ", score:  "+str(elt[2])+"</button> </tr>"
    code_html+="</table>"
    return render_template('historique.html',content=Markup(code_html))




# route pour rejouer une partie 

@app.route('/rejouer_partie', methods=['GET', 'POST'])

def rejouer_partie():
    # on recupere l'id de la partie 
    idpartie=request.args.get('idpartie')
    print("on rejoue la partie",idpartie)
    # on recupere les idcases inser dans la table case cartes pour pouvoir afficher toutes les cartes même celles qui ne sont pas cliquées et on les stocke dans la table idcases
    idcases=[]
    with engine.connect() as con:
      rs  = con.execute('select cac.IdCase from DLT1940A.CaseCarte cac where NPartie=\''+str(idpartie)+'\'  order by cac.IdCase asc')
      for row in rs:
        idcases.append(row[0])
    # on recupere les cases et images cliquées,les l'ordre des cliques inseré dans la base
    idcase_clique=[]
    ordrecoup=[]
    face_carte=[]
    code_html=""
    with engine.connect() as con:
      rs  = con.execute('select cp.IdCase,cp.Ordre, c.Image from DLT1940A.Coup cp, DLT1940A.CaseCarte cac,DLT1940A.Carte c where cp.NPartie=\''+str(idpartie)+'\'and cac.IdCase=cp.IdCase and cac.NPartie=cp.NPartie and cac.NCarte=c.NCarte order by cp.Ordre asc')
      for row in rs:
        idcase_clique.append(row[0])
        ordrecoup.append(row[1])
        face_carte.append(row[2])
    print(ordrecoup)
    print(idcases)
    print(face_carte)
    print(idcase_clique)
    # on recupere le nombre d'image insere pour la partie
    maVar=len(idcases)
    for i in idcases:
        code_html+= "<div class = \"memory-card\"> <img class =\"front-face\" id =\""+str(i)+"\" src = \"static/Images/lune.jpg\" /> </div>"
    # transmet les tables ordrecoup et idcase_clique au javascript
    code_html+="<script language=\"JavaScript\" type=\"text/javascript\"> var ordrecoup = "+str(ordrecoup)+"; var face_carte = "+str(face_carte)+"; var idcase_clique = "+str(idcase_clique)+"; var maVar = "+str(maVar)+"; </script>"
    
    return render_template('rejouer_partie.html',content=Markup(code_html))

### route pour le classemet par jour

@app.route('/classementJour', methods=['GET', 'POST'])

def classementJour():
    code_html = """<table> <tr> <th>Joueur</th> <th>Score</th></tr>"""
    strSQL = 'select * from DLT1940A.ClassementJour'
    with engine.connect() as con:
      rs = con.execute(strSQL)
      for row in rs:
         code_html += "<tr>"
         for value in row:
            code_html += "<td>"+str(value)+"</td>"
    
         code_html+="</tr>"
            
    return render_template('classementjour.html',content=Markup(code_html))

#### on fait ensuite trois route pour les trois niveau 
# classement nuveau 1
@app.route('/classementNiv1', methods=['GET', 'POST'])

def classement_niv1():
    code_html = """<table> <tr> <th>Joueur</th> <th>Score</th></tr>"""
    strSQL = 'select * from DLT1940A.Classement_niv1'
    with engine.connect() as con:
      rs = con.execute(strSQL)
      for row in rs:
         code_html += "<tr>"
         for value in row:
            code_html += "<td>"+str(value)+"</td>"
    
         code_html+="</tr>"
    code_html+="</table>"
            
    return render_template('classement_niveau.html',content=Markup(code_html))

# classement nuveau 2
@app.route('/classementNiv2', methods=['GET', 'POST'])

def classement_niv2():
    code_html = """<table> <tr> <th>Joueur</th> <th>Score</th></tr>"""
    strSQL = 'select * from DLT1940A.Classement_niv2'
    with engine.connect() as con:
      rs = con.execute(strSQL)
      for row in rs:
         code_html += "<tr>"
         for value in row:
            code_html += "<td>"+str(value)+"</td>"
    
         code_html+="</tr>"
        
    return render_template('classement_niveau.html',content=Markup(code_html))

    # classement nuveau 3
@app.route('/classementNiv3', methods=['GET', 'POST'])

def classement_niv3():
    code_html = """<table> <tr> <th>Joueur</th> <th>Score</th></tr>"""
    strSQL = 'select * from DLT1940A.Classement_niv3'
    with engine.connect() as con:
      rs = con.execute(strSQL)
      for row in rs:
         code_html += "<tr>"
         for value in row:
            code_html += "<td>"+str(value)+"</td>"
    
         code_html+="</tr>"
            
    return render_template('classement_niveau.html',content=Markup(code_html))





if __name__ == "__main__":
    app.secret_key = 'super secret key'
    app.config['SESSION_TYPE'] = 'filesystem'
    app.debug = True
    app.run()
