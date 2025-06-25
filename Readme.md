====================================================
     GUIDE D'UTILISATION SIMPLE
     Console de Durcissement Sécurité v1.0
====================================================

📌 DÉMARRAGE RAPIDE
-------------------

WINDOWS :
1. Faites un clic droit sur "start.bat"
2. Sélectionnez "Exécuter en tant qu'administrateur"
3. L'analyse se lance automatiquement
4. Le navigateur s'ouvre avec les résultats

LINUX :
1. Ouvrez un terminal
2. Tapez : sudo ./start.sh
3. L'analyse se lance automatiquement
4. Le navigateur s'ouvre avec les résultats


📊 COMPRENDRE LES RÉSULTATS
---------------------------

✅ CONFORME (vert) = Tout va bien, aucune action nécessaire
❌ NON CONFORME (rouge) = Problème détecté, correction recommandée
⚠️  ERREUR (jaune) = Vérification impossible, vérifier manuellement
ℹ️  INFO (bleu) = Information, à vérifier selon votre contexte


🔧 QUE FAIRE ENSUITE ?
----------------------

1. CONSULTER : Lisez chaque point "Non conforme"
2. COMPRENDRE : Chaque point explique le problème
3. DÉCIDER : Certains points peuvent être volontaires
4. CORRIGER : Utilisez les commandes fournies si nécessaire


⚡ COMMANDES UTILES
-------------------

Pour appliquer une correction individuelle :
- Copiez la commande affichée
- Ouvrez PowerShell (Windows) ou Terminal (Linux) en admin
- Collez et exécutez la commande

Pour sauvegarder le rapport :
- Cliquez sur "Exporter le rapport"
- Ou faites Ctrl+P pour imprimer/PDF


❓ PROBLÈMES FRÉQUENTS
----------------------

"Erreur: droits administrateur requis"
→ Relancez avec un clic droit > Exécuter en tant qu'administrateur

"Le navigateur ne s'ouvre pas"
→ Ouvrez manuellement le fichier index.html

"Aucun résultat affiché"
→ Attendez la fin de l'analyse (peut prendre 1-2 minutes)
→ Rafraîchissez la page (F5)


📁 STRUCTURE DES DOSSIERS
-------------------------

security-hardening-console/
├── start.bat / start.sh    → LANCEZ CECI !
├── index.html              → Interface web (s'ouvre automatiquement)
├── scripts/                → Ne pas modifier
├── verifications/          → Ajoutez vos vérifications ici
│   ├── windows/           → Vérifications Windows (.yaml)
│   └── linux/             → Vérifications Linux (.yaml)
├── lang/                   → Traductions
└── results.json           → Résultats (généré automatiquement)


🆘 SUPPORT
----------

En cas de problème :
1. Vérifiez que vous êtes administrateur
2. Consultez le README.md pour plus de détails
3. Vérifiez les logs dans la console

====================================================
Rappel : Testez TOUJOURS en environnement de test
avant d'appliquer des modifications en production !
====================================================