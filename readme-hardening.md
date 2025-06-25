# Console de Durcissement Sécurité - Windows/Linux

## 🛡️ Description

Console web autonome permettant l'analyse et le durcissement de la configuration de sécurité des serveurs Windows et Linux. Basée sur les recommandations de l'ANSSI, du CIS (Center for Internet Security) et de Microsoft.

## 📁 Structure du projet

```
security-hardening-console/
├── index.html              # Console web principale
├── README.md              # Documentation (ce fichier)
├── LICENSE                # Licence du projet (MIT)
├── lang/                  # Fichiers de traduction
│   ├── fr.json           # Traduction française
│   └── en.json           # Traduction anglaise
└── verifications/         # Points de vérification
    ├── windows/
    │   ├── ipv6.yaml
    │   ├── firewall.yaml
    │   ├── antivirus.yaml
    │   └── ...
    └── linux/
        ├── ipv6.yaml
        ├── ssh.yaml
        ├── updates.yaml
        └── ...
```

## 🚀 Installation et utilisation

### Prérequis

- Un navigateur web moderne (Chrome, Firefox, Edge)
- Droits administrateur/root sur le système à analyser
- PowerShell 5.0+ pour Windows
- Bash 4.0+ pour Linux

### Installation

1. Clonez ou téléchargez le projet :
```bash
git clone https://github.com/votre-repo/security-hardening-console.git
cd security-hardening-console
```

2. Ouvrez `index.html` dans votre navigateur

### Utilisation locale

1. **Sélection du système** : Choisissez Windows ou Linux
2. **Niveau de sécurité** : Sélectionnez le niveau souhaité (Basique, Intermédiaire, Avancé)
3. **Analyse** : Cliquez sur "Analyser" pour lancer l'audit
4. **Sélection** : Cochez les corrections à appliquer
5. **Application** : Cliquez sur "Appliquer" pour générer le script de correction

### Utilisation distante (roadmap)

La fonctionnalité d'analyse distante sera disponible dans une prochaine version. Elle permettra d'analyser des serveurs distants via SSH (Linux) ou WinRM (Windows).

## 🔧 Configuration

### Ajouter une vérification personnalisée

1. Créez un fichier YAML dans le dossier approprié :
   - `verifications/windows/` pour Windows
   - `verifications/linux/` pour Linux

2. Utilisez le format suivant :

```yaml
id: custom-check
title:
  fr: "Titre en français"
  en: "English title"
description:
  fr: "Description détaillée en français"
  en: "Detailed description in English"
severity: high  # critical, high, medium, low
category: security
level: basic    # basic, intermediate, advanced
check:
  command: "commande de vérification"
  expected: