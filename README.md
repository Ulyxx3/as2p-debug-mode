# 🛡️ Antivirus Survivors 2003 Professional - Debug Mode & Trainer

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20Steam%20Deck-blue.svg)](#installation)
[![Engine](https://img.shields.io/badge/Engine-Godot%204.7.1-478cbf.svg)](#technologies)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Un menu de débogage et trainer complet, parfaitement intégré au style visuel rétro Windows 2003 du jeu **Antivirus Survivors 2003 Professional**.

Ce mod fonctionne aussi bien sur **Windows** que sur **Linux / Steam Deck (SteamOS)**, sans aucune dépendance externe requise pour l'installation !

---

## 🎮 Fonctionnalités du Menu Debug

Le menu s'ouvre et se ferme instantanément en jeu en appuyant sur **F1**, **F3** ou **`** (tilde).

### 📊 1. Statistiques du Joueur (18 Stats en temps réel)
* Modification incrémentale en direct de toutes les statistiques internes :
  * **Survie** : PV Maximum, Régénération de PV, Protection (Armure), Perte de Paquets (Esquive).
  * **Attaque** : Force d'Attaque (Dégâts x), Puissance, Cadence de Tir (Cooldown), Nombre de Tirs simultanés, Vitesse des Projectiles, Taille des Armes.
  * **Critiques** : Chance Critique, Dégâts Critiques Multiplicateurs.
  * **Utilitaire & Mobilité** : Vitesse de Déplacement, Vitesse du Processeur (CPU Proc Speed), Magnétisme (Rayon d'aspiration), Chance (Luck).
  * **Gains** : Multiplicateurs de gain d'EXP et de Pièces.
* Boutons rapides de soin complet à 100%, +10 HP, -10 HP.
* Buff global rapide (+25% / +50% / +100% sur toutes les stats) et réinitialisation instantanée.

### ⚔️ 2. Équipement & Armes
* **Armes** : Donnez-vous n'importe laquelle des 24 armes officielles du jeu (AVD, Buddy, Solitaire, Fraps, Modem 56k, Pinball, etc.) ou montez leur niveau.
* **Pilotes (Drivers)** : Appliquez les pilotes de votre choix à vos armes équipées.
* **Plugins** : Activez n'importe quel plugin en cours de run.

### 📈 3. Progression du Run & Méta-Progression
* **Niveaux & EXP** : +1, +5, +10 ou +25 Niveaux d'un clic (avec ouverture de l'écran de sélection d'amélioration) et injection directe d'EXP (+100, +1 000, +5 000).
* **Pièces & Clés du Run** : Ajoutez instantanément des pièces (+100, +1 000, +10 000) et des clés (+1, +5, +10) avec son et mise à jour dynamique du HUD en direct.
* **Beanz (Monnaie permanente)** : Ajoutez des milliers de Beanz (+500, +5 000, +50 000) sauvegardés immédiatement dans votre profil.
* **🔓 Débloquer Tout** : Débloquez instantanément l'intégralité du contenu du jeu (armes, objets, personnages et thèmes de bureau).

### ⚡ 4. Triche & Tests de Vagues
* **Invulnérabilité (God Mode)** : Mode invincible basculable à volonté.
* **Nettoyage de Carte (Kill All)** : Éliminez tous les virus et ennemis à l'écran instantanément.
* **Vitesse du Jeu (Time Scale)** : Réglez la vitesse du jeu (`x0.25`, `x0.5`, `x1.0`, `x1.5`, `x2.0`, `x3.0`, `x5.0`). La vitesse sélectionnée reste active en jeu même après fermeture du menu.
* **Contrôle des Vagues & Boss** :
  * Finir instantanément le timer d'arène.
  * Faire apparaître le *Safe Folder* d'objectif.
  * Changer le numéro de Round (Rounds 1 à 5).
  * Invoquer un boss à volonté (Beach Ball, Recycle Bin, Caesar Chimp).
  * Faire spawner n'importe quel fichier cliquable (RAM, Torrent, Keygen, Defrag, etc.).

---

## 🚀 Installation

### 🪟 Windows
1. Téléchargez ou clonez ce dépôt dans un dossier de votre choix :
   ```bash
   git clone https://github.com/Ulysse/as2p-debug-mode.git
   ```
2. Double-cliquez simplement sur **`patch.bat`** (ou lancez `python patch.py`).
3. L'installeur détecte automatiquement votre dossier Steam, crée une sauvegarde automatique (`AVS03Pro.pck.bak`) et patche le jeu.
4. Lancez le jeu via Steam et appuyez sur **F1** ou **F3** !

### 🐧 Linux & Steam Deck (SteamOS)
1. Ouvrez un terminal dans le dossier du dépôt :
   ```bash
   git clone https://github.com/Ulysse/as2p-debug-mode.git
   cd as2p-debug-mode
   ```
2. Rendez le script exécutable et lancez-le :
   ```bash
   chmod +x patch.sh
   ./patch.sh
   ```
   *(Ou lancez `python3 patch.py`)*
3. L'installeur détecte automatiquement l'installation Steam native, Flatpak ou Proton sur Steam Deck.

---

## 🔄 Désinstallation (Restauration du Jeu Original)

Pour revenir à tout moment au jeu officiel d'origine :
* **Windows** : Double-cliquez sur **`restore.bat`** (ou `python patch.py --restore`).
* **Linux / Steam Deck** : Lancez **`./restore.sh`** (ou `python3 patch.py --restore`).

---

## 🛠️ Guide Développeur (Continuer le Projet)

Si vous souhaitez modifier le code source du mod et ajouter de nouvelles fonctionnalités :

1. Les fichiers sources en clair (**GDScript**) se trouvent dans `src/` :
   * `src/scenes/ui/debug_menu/debug_menu.gd` : Code complet de l'interface et des fonctions du trainer.
   * `src/scenes/main/main.gd` : Point d'accroche des raccourcis F1/F3.
   * `src/scenes/autoload/game_events.gd` : Gestionnaire global d'événements et ouverture de l'overlay.
   * `src/scenes/component/health_component.gd` : Support du God Mode.
2. Pour recompiler vos modifications :
   * Téléchargez `gdre_tools` (Windows ou Linux) depuis [Godot RE Tools](https://github.com/godot-re-tools/godot-re-tools/releases).
   * Placez `gdre_tools.exe` (ou `gdre_tools.x86_64`) dans le sous-dossier `tools/`.
   * Lancez simplement :
     ```bash
     python build.py
     ```
   * Le script compile les fichiers en bytecode Godot 4.5/4.7 (`.gdc`) dans `mod_files/` et patche automatiquement votre jeu local pour tester immédiatement !

---

## 📜 Licence

Ce projet est sous licence [MIT](LICENSE).
