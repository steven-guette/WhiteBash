# **DisplayFX**
**Module d'affichage avancé pour terminal avec gestion des messages typés, titres encadrés et bannières stylisées.**

---

## 🎯 **Fonctionnalités principales**
- **Messages typés colorés** : Affiche des messages avec types prédéfinis (info, warning, error, valid).
- **Alignement flexible** : Aligne les textes à gauche, au centre ou à droite du terminal.
- **Titres encadrés** : Génère des titres encadrés avec une touche stylisée.
- **Bannières visuelles** : Support des polices `figlet` et coloration avec `lolcat` pour des bannières personnalisées.
- **Text Wrapping** : Coupe automatiquement les longs textes selon la largeur du terminal.

---

## 🛠️ **Prérequis**
- **Dépendances internes** : `Chroma`, `WShield`, `TermCTRL`, `StrOps`, `FrameGen`.
- **Optionnel** :
    - `lolcat` : Pour des titres/bannières colorés.
    - `figlet` : Pour générer des polices stylisées pour les bannières.

Installer les dépendances optionnelles :
```bash
sudo apt install lolcat figlet
```

## 🚀 **Utilisation**
🚀 Utilisation
### 1. **Messages Typés**
Affiche des messages avec un type prédéfini et des options d’alignement.

**Syntaxe** :
```Bash
DisplayFX_message "type" "texte" [newlines_up=1] [newlines_down=0] [alignement=left]
```


| **Type** | **Couleur** |
|----------|-------------|
| error    | 	Rouge      |
| warning  | 	Jaune      |
| info     | 	Cyan       |
| valid    | 	Vert       |

**Exemple** :
```Bash
DisplayFX_message "info" "Lancement du script..." 1 0 center
DisplayFX_message "warning" "Attention : seuil de mémoire atteint." 1 1 left
DisplayFX_message "error" "Erreur critique : fichier manquant !" 2 2 right
```

### 2. **Titres Encadrés et Colorés par Lolcat**

**Syntaxe** :
```Bash
DisplayFX_print_lolcat_title "titre"
```

**Exemple** :
```Bash
DisplayFX_print_lolcat_title "Bienvenue dans WhiteBash"
```

**Résultat** :
Un titre encadré, coloré avec lolcat si disponible.

### 3. **Bannières Stylisées**
Pour un véritable rendu, figlet est indispensable.

**Syntaxe** :
```Bash
DisplayFX_print_banner "texte" [figlet_font]
```

**Exemple** :
```Bash
DisplayFX_print_banner "WhiteBash Framework"
DisplayFX_print_banner "Hello World" "slant"
```

**Résultat** :
Une bannière stylisée avec une police figlet aléatoire ou spécifiée, coloré avec lolcat si installé.

### 4. **Alignement et Text Wrapping**
Aligner un texte dans le terminal :

- left (par défaut)
- center
- right

**Exemple** :
```Bash
DisplayFX_print "Ceci est un texte centré" 1 1 center
```

**Afficher un texte sur plusieurs lignes s'il dépasse une certaine longueur** :
```Bash
DisplayFX_print_wrapped "Un très long texte qui doit être automatiquement coupé pour s'adapter à la longueur maximale." 40 center
```

## 🎓 **Exemple Complet**
Voici un exemple combinant plusieurs fonctions de DisplayFX :

```Bash
#!/bin/bash

# Chargement de Nexus et des modules nécessaires
. chemin/vers/Nexus.sh
Nexus_link_with DisplayFX

# Affichage des messages
DisplayFX_message "info" "Lancement du script..." 1 0 center
DisplayFX_message "valid" "Configuration réussie !" 1 1
DisplayFX_message "warning" "Attention : seuil de mémoire atteint." 1 0 right
DisplayFX_message "error" "Erreur critique !" 2 2 center

# Titre et bannière
DisplayFX_print_lolcat_title "Mon Titre Stylé"
DisplayFX_print_banner "Framework WhiteBash"

# Texte aligné et wrapping
DisplayFX_print "Ceci est un texte centré." 1 1 center
DisplayFX_print_wrapped "Un très long texte qui sera coupé automatiquement selon la longeur maximale qui a été définie" 50 center
```

## 📦 **Personnalisation des messages**
Les couleurs des types de messages (error, warning, etc.) sont configurées dans la variable DISPLAYFX_MESSAGE_COLORS. 

Vous pouvez les ajuster (ou en ajouter) selon vos besoins :

```Bash
declare -grA DISPLAYFX_MESSAGE_COLORS=(
    ["error"]=red ["warning"]=yellow ["info"]=cyan ["valid"]=green
)
```

## ⚠️ **Notes Importantes**
- Le module vérifie la largeur du terminal grâce à TermCTRL et ajuste le comportement d'affichage si celle-ci est trop petite.
- Pour un affichage optimal, assurez-vous que le terminal respecte une largeur minimale.

## © **Licence**
Ce module fait partie du framework WhiteBash, distribué sous licence MIT.