# Guide des Images pour le Rapport Professionnel

## Images Requises et Emplacements

### 1. **Figure 1: System Overview - Student Reservation Workflow and Architecture**
**Emplacement:** Après section 1.5 (ligne ~72)
**Type:** Diagramme d'architecture système
**Contenu suggéré:**
- Flux utilisateur: Étudiant → Application → Firebase → Personnel
- Composants principaux: App mobile, Backend Firebase, Services de paiement
- Interactions principales: Réservation, Paiement, Validation QR

### 2. **Figure 2: Mobile Application User Interface and Role-Based Access**
**Emplacement:** Après section 1.5 (ligne ~88)
**Type:** Captures d'écran de l'interface utilisateur
**Contenu suggéré:**
- Interface étudiant (accueil, réservation)
- Interface personnel (scanner QR)
- Interface admin (tableau de bord)

### 3. **Figure 3: User Personas and Interaction Scenarios**
**Emplacement:** Section 2.2 (ligne ~130)
**Type:** Diagramme des personas et scénarios
**Contenu suggéré:**
- Persona étudiant avec workflow de réservation
- Persona personnel avec workflow de validation
- Persona administrateur avec workflow de gestion

### 4. **Figure 4: Functional Requirements Overview**
**Emplacement:** Section 3.1 (ligne ~178)
**Type:** Diagramme des exigences fonctionnelles
**Contenu suggéré:**
- Modules: Étudiant, Personnel, Admin
- Fonctionnalités principales par module
- Flux de données entre modules

### 5. **Figure 5: Student Module User Interface**
**Emplacement:** Section 3.1.1 (ligne ~197)
**Type:** Captures d'écran détaillées
**Contenu suggéré:**
- Écran d'accueil étudiant
- Processus de réservation
- Génération et affichage du QR code

### 6. **Figure 6: Payment Integration Workflow**
**Emplacement:** Section 3.1.4 (ligne ~225)
**Type:** Diagramme de flux de paiement
**Contenu suggéré:**
- Intégration D17 et Flouci
- Workflow de confirmation de paiement
- Gestion des échecs et rollback

### 7. **Figure 7: Use Cases Diagram**
**Emplacement:** Section 3.3 (ligne ~275)
**Type:** Diagramme UML des cas d'usage
**Contenu suggéré:**
- Acteurs: Étudiant, Personnel, Admin
- Cas d'usage principaux
- Relations et dépendances

### 8. **Figure 8: Technical Architecture - Flutter and Firebase Integration**
**Emplacement:** Section 4.2 (ligne ~337)
**Type:** Architecture technique détaillée
**Contenu suggéré:**
- Architecture MVVM
- Services Firebase utilisés
- Intégrations externes (paiements, etc.)

### 9. **Figure 9: Firestore Database Schema and Collections Structure**
**Emplacement:** Section 4.3 (ligne ~361)
**Type:** Schéma de base de données
**Contenu suggéré:**
- Collections Firestore
- Relations entre documents
- Index et optimisations

### 10. **Figure 10: Performance Metrics and Response Time Analysis**
**Emplacement:** Section 5.2 (ligne ~424)
**Type:** Graphiques de performance
**Contenu suggéré:**
- Temps de réponse par opération
- Métriques de throughput
- Comparaisons avant/après

### 11. **Figure 11: Infrastructure Usage and Scalability Metrics**
**Emplacement:** Section 5.5 (ligne ~448)
**Type:** Métriques d'infrastructure
**Contenu suggéré:**
- Utilisation Firebase (reads/writes)
- Consommation bande passante
- Métriques de scalabilité

## Recommandations pour la Création des Images

### Outils Suggérés:
- **Diagrammes:** Draw.io, Lucidchart, ou Figma
- **Captures d'écran:** Directement depuis l'app + annotations
- **Graphiques:** Excel, Google Sheets, ou outils de monitoring Firebase

### Standards de Qualité:
- **Résolution:** Minimum 1920x1080 pour les diagrammes
- **Format:** PNG pour les captures, SVG pour les diagrammes si possible
- **Lisibilité:** Texte minimum 12pt, contrastes élevés
- **Cohérence:** Palette de couleurs uniforme

### Placement dans le Document:
- Centrer les images
- Ajouter des légendes descriptives
- Référencer dans le texte: "comme illustré dans la Figure X"
- Numéroter séquentiellement

## Exemple de Référencement:

```
Le système suit une architecture distribuée client-cloud comme illustré dans la 
Figure 1. Cette architecture permet une séparation claire des responsabilités 
entre l'interface mobile et les services backend.

[IMAGE: Figure 1: System Overview - Student Reservation Workflow and Architecture]

La Figure 1 montre comment les étudiants interagissent avec l'application mobile 
pour créer des réservations, qui sont ensuite traitées par les services Firebase 
avant d'être validées par le personnel via le scanner QR.
```