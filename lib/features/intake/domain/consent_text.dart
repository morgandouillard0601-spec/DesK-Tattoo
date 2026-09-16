/// Textes du contrat de consentement présenté au client avant tatouage.
///
/// Ce fichier est volontairement isolé : le contenu est juridique et doit
/// pouvoir être relu ou ajusté sans toucher à l'interface.
class ConsentText {
  const ConsentText._();

  static const String title = 'Consentement éclairé et contrat de prestation';

  static const String intro =
      'Avant toute prestation de tatouage, la réglementation impose de '
      'recueillir votre consentement éclairé ainsi que quelques informations '
      'de santé. Merci de lire attentivement et de répondre sincèrement : '
      'certaines réponses peuvent conduire le tatoueur à reporter la séance.';

  /// Clauses reprises dans le PDF, dans l'ordre.
  static const List<ConsentClause> clauses = <ConsentClause>[
    ConsentClause(
      title: 'Majorité et identité',
      body:
          'Je déclare être majeur(e) et fournir des informations exactes. '
          'Une pièce d\'identité peut m\'être demandée sur place.',
    ),
    ConsentClause(
      title: 'Caractère définitif',
      body:
          'Je comprends qu\'un tatouage est une modification permanente de la '
          'peau. Le détatouage est long, coûteux et ne garantit pas la '
          'disparition complète du motif. J\'ai validé le motif, sa taille et '
          'son emplacement avec le tatoueur avant la séance.',
    ),
    ConsentClause(
      title: 'Risques',
      body:
          'J\'ai été informé(e) des risques : douleur, rougeurs, gonflement, '
          'démangeaisons, saignements légers, réaction allergique aux encres, '
          'infection en cas de soins inadaptés, cicatrisation irrégulière, '
          'variation de rendu des couleurs selon ma peau.',
    ),
    ConsentClause(
      title: 'Hygiène',
      body:
          'Le studio utilise du matériel stérile à usage unique pour les '
          'aiguilles et les cartouches, et applique un protocole de '
          'désinfection entre chaque client.',
    ),
    ConsentClause(
      title: 'Déclaration de santé',
      body:
          'Je certifie avoir signalé toute allergie, traitement en cours, '
          'problème de coagulation, maladie cardiaque, diabète, épilepsie, '
          'grossesse ou allaitement. Je déclare ne pas être sous l\'emprise '
          'de l\'alcool ou de stupéfiants.',
    ),
    ConsentClause(
      title: 'Soins après séance',
      body:
          'Je m\'engage à suivre les consignes de cicatrisation remises par le '
          'tatoueur : nettoyage doux, crème recommandée, pas de grattage, pas '
          'de piscine, sauna ni exposition au soleil pendant la cicatrisation. '
          'Le studio ne peut être tenu responsable d\'un défaut de rendu lié à '
          'des soins non respectés.',
    ),
    ConsentClause(
      title: 'Retouches et paiement',
      body:
          'Les conditions de retouche et d\'acompte m\'ont été présentées. '
          'L\'acompte versé engage la réservation du créneau et reste acquis '
          'au studio en cas d\'annulation tardive.',
    ),
    ConsentClause(
      title: 'Données personnelles',
      body:
          'Mes informations et ce document sont conservés par le studio pour '
          'répondre à ses obligations et assurer le suivi de la prestation. '
          'Les données de santé sont stockées de façon sécurisée et ne sont '
          'accessibles qu\'au studio. Je peux demander leur consultation, leur '
          'rectification ou leur suppression auprès du studio.',
    ),
  ];

  /// Cases à cocher. `required` = blocage de la signature si non cochée.
  static const List<ConsentCheckbox> checkboxes = <ConsentCheckbox>[
    ConsentCheckbox(
      key: 'accepted_terms',
      label:
          'J\'ai lu et j\'accepte le contrat de prestation et le caractère '
          'définitif du tatouage.',
      required: true,
    ),
    ConsentCheckbox(
      key: 'accepted_health',
      label:
          'Je certifie l\'exactitude de ma déclaration de santé et je suis '
          'majeur(e).',
      required: true,
    ),
    ConsentCheckbox(
      key: 'accepted_aftercare',
      label:
          'Je m\'engage à respecter les consignes de cicatrisation qui me '
          'seront remises.',
      required: true,
    ),
    ConsentCheckbox(
      key: 'accepted_image_rights',
      label:
          'J\'autorise le studio à photographier le tatouage et à le publier '
          '(facultatif).',
      required: false,
    ),
  ];

  /// Questions santé du formulaire. Réponses stockées en JSON.
  static const List<HealthQuestion> healthQuestions = <HealthQuestion>[
    HealthQuestion(
      key: 'allergies',
      label: 'Allergies connues (latex, encres, métaux, médicaments)',
      hint: 'Aucune, ou précise lesquelles',
    ),
    HealthQuestion(
      key: 'treatments',
      label: 'Traitements médicaux en cours',
      hint: 'Aucun, ou précise lesquels',
    ),
    HealthQuestion(
      key: 'medical_history',
      label: 'Antécédents (diabète, épilepsie, cœur, coagulation, peau)',
      hint: 'Aucun, ou précise lesquels',
    ),
    HealthQuestion(
      key: 'pregnancy',
      label: 'Grossesse ou allaitement en cours',
      hint: 'Non, ou précise',
      isShort: true,
    ),
    HealthQuestion(
      key: 'emergency_contact',
      label: 'Personne à contacter en cas d\'urgence',
      hint: 'Nom et téléphone',
      isShort: true,
    ),
  ];

  static const String signatureNotice =
      'En signant ci-dessous, je confirme avoir lu l\'ensemble du contrat et '
      'accepté les clauses cochées à l\'étape précédente.';

  static const String minorBlockedMessage =
      'Le tatouage des mineurs nécessite la présence et l\'autorisation écrite '
      'du représentant légal. Merci de contacter directement le studio.';
}

class ConsentClause {
  const ConsentClause({required this.title, required this.body});

  final String title;
  final String body;
}

class ConsentCheckbox {
  const ConsentCheckbox({
    required this.key,
    required this.label,
    required this.required,
  });

  final String key;
  final String label;
  final bool required;
}

class HealthQuestion {
  const HealthQuestion({
    required this.key,
    required this.label,
    required this.hint,
    this.isShort = false,
  });

  final String key;
  final String label;
  final String hint;

  /// Champ sur une seule ligne plutôt qu'une zone de texte.
  final bool isShort;
}
