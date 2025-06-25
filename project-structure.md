# Structure du Projet - Console de Durcissement Sécurité

## 📁 Organisation des fichiers

```
security-hardening-console/
│
├── 🚀 FICHIERS DE LANCEMENT (Double-clic pour démarrer)
│   ├── start.bat                    # Windows : clic droit > Exécuter en tant qu'admin
│   └── start.sh                     # Linux : chmod +x start.sh && sudo ./start.sh
│
├── 🌐 INTERFACE WEB
│   ├── index.html                   # Interface de visualisation (s'ouvre automatiquement)
│   ├── generator.html               # Générateur de vérifications YAML
│   ├── results.json                 # Résultats d'analyse (généré automatiquement)
│   ├── config.json                  # Configuration (langue, préférences) - généré automatiquement
│   │
│   ├── 🎨 css/                      # Styles
│   │   ├── style.css               # Styles principaux pour index.html
│   │   └── generator.css           # Styles spécifiques au générateur
│   │
│   └── 📜 js/                       # Scripts JavaScript
│       ├── app.js                  # Contrôleur principal de l'application
│       ├── translations.js         # Module de gestion multilingue
│       ├── results.js              # Module d'affichage des résultats
│       └── generator.js            # Logique du générateur YAML
│
├── 📚 DOCUMENTATION
│   ├── README.md                    # Documentation complète avec FAQ
│   ├── GUIDE_UTILISATION.txt        # Guide simple pour utilisateurs
│   ├── LICENSE                      # Licence AGPLv3
│   └── STRUCTURE_PROJET.md          # Ce fichier
│
├── 🔧 SCRIPTS D'ANALYSE
│   └── scripts/
│       ├── analyze-windows.ps1      # Script PowerShell pour Windows
│       └── analyze-linux.sh         # Script Bash pour Linux
│
├── 🔍 VÉRIFICATIONS
│   └── verifications/
│       ├── windows/                 # Vérifications Windows
│       │   ├── firewall.yaml       # État du pare-feu Windows
│       │   ├── updates.yaml        # Mises à jour Windows
│       │   └── ...                 # Ajoutez vos fichiers .yaml ici
│       │
│       └── linux/                   # Vérifications Linux
│           ├── firewall.yaml       # Pare-feu Linux (multi-distribution)
│           ├── ssh-root-login.yaml # Désactivation connexion SSH root
│           └── ...                 # Ajoutez vos fichiers .yaml ici
│
└── 🌍 LANGUES
    └── lang/
        ├── languages.json           # Liste des langues disponibles
        ├── en.json                  # Traduction anglaise (par défaut)
        ├── fr.json                  # Traduction française
        └── ...                      # Ajoutez d'autres langues ici
```

## 🎯 Flux de fonctionnement

1. **Lancement** : L'utilisateur double-clique sur `start.bat` ou `start.sh`
2. **Vérification** : Le script vérifie les droits admin et les prérequis
3. **Chargement** : Les fichiers YAML sont chargés depuis `verifications/`
4. **Analyse** : Les commandes de vérification sont exécutées
5. **Rapport** : Les résultats sont sauvés dans `results.json`
6. **Affichage** : Le navigateur s'ouvre avec `index.html`
7. **Consultation** : L'utilisateur consulte les résultats et recommandations

## 🔑 Points clés pour les utilisateurs

### Pour utiliser la console :
- **Aucune installation requise** : Tout fonctionne avec les outils natifs
- **Simple** : Double-clic pour lancer
- **Sûr** : Aucune modification sans votre accord
- **Extensible** : Ajoutez vos propres vérifications

### Pour ajouter une vérification :
1. Créez un fichier `.yaml` dans le bon dossier
2. Utilisez le format simple (voir exemples)
3. Relancez l'analyse

### Format YAML minimal :
```yaml
id: ma-verification
title:
  fr: "Titre en français"
description:
  fr: "Description du problème"
severity: high
category: security
level: basic
check:
  windows:
    command: "commande PowerShell"
  linux:
    command: "commande bash"
remediation:
  windows:
    local:
      command: "commande de correction"
  linux:
    local:
      command: "commande de correction"
```

## 🛡️ Sécurité

- **Pas de connexion Internet** : Tout est local
- **Pas de modification automatique** : Vous gardez le contrôle
- **Code source visible** : Tout est transparent
- **Logs détaillés** : Vous voyez ce qui est fait

## 📝 Notes importantes

1. **Windows** : PowerShell 5.0+ requis (inclus dans Windows 10/Server 2016+)
2. **Linux** : Bash 4.0+ requis (standard sur toutes les distributions récentes)
3. **Navigateur** : N'importe quel navigateur moderne
4. **Droits** : Admin/root requis pour l'analyse seulement

## 🚀 Démarrage rapide

```bash
# Windows (PowerShell admin)
cd security-hardening-console
.\start.bat

# Linux (Terminal)
cd security-hardening-console
chmod +x start.sh
sudo ./start.sh
```

---

**Rappel** : Cette console est un outil d'aide à la décision. Testez toujours les modifications dans un environnement de test avant la production.