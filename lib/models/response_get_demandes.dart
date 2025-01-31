import 'response_get_liste_pannes.dart';

class ResponseGetDemandesList {
  List<Demande>? demandes;

  ResponseGetDemandesList({this.demandes});

  ResponseGetDemandesList.fromJson(Map<String, dynamic> json) {
    if (json['demandes'] != null) {
      demandes = <Demande>[];
      json['demandes'].forEach((v) {
        demandes!.add(new Demande.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.demandes != null) {
      data['demandes'] = this.demandes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}


class Demand {
  List<Demande> demandes;

  Demand({required this.demandes});

  factory Demand.fromJson(Map<String, dynamic> json) {
    return Demand(
      demandes: (json['demandes'] as List).map((i) => Demande.fromJson(i)).toList(),
    );
  }
}


class Demande {
  String? id;
  String? ref;
  String? type;
  String? caseId;
  String? userId;
  String? prestataireId;
  String? client;
  String? telephone;
  String? accesReseau;
  String? activitesService;
  String? typeProbleme;
  String? description;
  String? numLigne;
  String? nomPrenom;
  String? numContact;
  String? adresse;
  String? ville;
  String? nomPlanTarifaire;
  String? dateIncident;
  String? situationAbonnement;
  String? routeur;
  String? power;
  String? pon;
  String? los;
  String? internet;
  String? wifi;
  String? cablageRedemarrageEquipement;
  String? verificationCablagePto;
  String? plaqueId;
  String? dateRdv;
  String? longitude;
  String? latitude;
  String? photoProbleme;
  String? photoSignal;
  String? photoResolutionProbleme;
  String? photoSup1;
  String? photoSup2;
  String? commentaire;
  String? commentaireSup;
  String? articleId;
  String? adresseMac;
  String? snRouteur;
  String? snGpon;
  String? macAnBox;
  String? snAnBox;
  String? snAnGpon;
  String? dateResolution;
  String? typeId;
  String? etatId;
  String? archiveId;
  String? created;
  String? etatName;
  String? plaqueName;
  String? loginSip;
  List<Commentaire>? commentaires;
  List<String>? demandePanne;
  List<String>? demandeSolution;
  List<Panne>? pannes;

  var etape = 1;

  Demande({
    this.id,
    this.ref,
    this.caseId,
    this.type,
    this.userId,
    this.prestataireId,
    this.client,
    this.telephone,
    this.accesReseau,
    this.activitesService,
    this.typeProbleme,
    this.description,
    this.numLigne,
    this.nomPrenom,
    this.numContact,
    this.adresse,
    this.ville,
    this.nomPlanTarifaire,
    this.dateIncident,
    this.situationAbonnement,
    this.routeur,
    this.power,
    this.pon,
    this.los,
    this.internet,
    this.wifi,
    this.cablageRedemarrageEquipement,
    this.verificationCablagePto,
    this.plaqueId,
    this.dateRdv,
    this.longitude,
    this.latitude,
    this.photoProbleme,
    this.photoSignal,
    this.photoResolutionProbleme,
    this.photoSup1,
    this.photoSup2,
    this.commentaire,
    this.commentaireSup,
    this.articleId,
    this.adresseMac,
    this.snRouteur,
    this.snGpon,
    this.macAnBox,
    this.snAnBox,
    this.snAnGpon,
    this.dateResolution,
    this.typeId,
    this.etatId,
    this.archiveId,
    this.created,
    this.etatName,
    this.plaqueName,
    this.loginSip,
    this.commentaires,
    this.demandePanne,
    this.demandeSolution,
    this.pannes,
  });

  factory Demande.fromJson(Map<String, dynamic> json) {
    return Demande(
      id: json['id'],
      ref: json['ref'],
      caseId: json['case_id'],
      type: json['type'],
      userId: json['user_id'],
      prestataireId: json['prestataire_id'],
      client: json['client'],
      telephone: json['telephone'],
      accesReseau: json['acces_reseau'],
      activitesService: json['activites_service'],
      typeProbleme: json['type_probleme'],
      description: json['description'],
      numLigne: json['num_ligne'],
      nomPrenom: json['nom_prenom'],
      numContact: json['num_contact'],
      adresse: json['adresse'],
      ville: json['ville'],
      nomPlanTarifaire: json['nom_plan_tarifaire'],
      dateIncident: json['date_incident'],
      situationAbonnement: json['situation_abonnement'],
      routeur: json['routeur'],
      power: json['power'],
      pon: json['pon'],
      los: json['los'],
      internet: json['internet'],
      wifi: json['wifi'],
      cablageRedemarrageEquipement: json['cablage_redemarrage_equipement'],
      verificationCablagePto: json['verification_cablage_pto'],
      plaqueId: json['plaque_id'],
      dateRdv: json['date_rdv'],
      longitude: json['longitude'],
      latitude: json['latitude'],
      photoProbleme: json['photo_probleme'],
      photoSignal: json['photo_signal'],
      photoResolutionProbleme: json['photo_resolution_probleme'],
      photoSup1: json['photo_sup1'],
      photoSup2: json['photo_sup2'],
      commentaire: json['commentaire'],
      commentaireSup: json['commentaire_sup'],
      articleId: json['article_id'],
      adresseMac: json['adresse_mac'],
      snRouteur: json['sn_routeur'],
      snGpon: json['sn_gpon'],
      macAnBox: json['mac_an_box'],
      snAnBox: json['sn_an_box'],
      snAnGpon: json['sn_an_gpon'],
      dateResolution: json['date_resolution'],
      typeId: json['type_id'],
      etatId: json['etat_id'],
      archiveId: json['archive_id'],
      created: json['created'],
      etatName: json['etat_name'],
      plaqueName: json['plaque_name'],
      loginSip: json['login_sip'],
      commentaires: json['commentaires'] != null ? (json['commentaires'] as List).map((i) => Commentaire.fromJson(i)).toList() : null,
      demandePanne: json['DemandePanne'] != null ? List<String>.from(json['DemandePanne']) : null,
      demandeSolution: json['DemandeSolution'] != null ? List<String>.from(json['DemandeSolution']) : null,
      pannes: json['pannes'] != null ? (json['pannes'] as List).map((i) => Panne.fromJson(i)).toList() : null,
    );
  }

  // Method to get the list of pannes as a string
  String getPannesListString() {
    if (pannes == null || pannes!.isEmpty) return "";
    return pannes!.map((panne) => panne.name ?? "").join(", ");
  }

  // Method to get the list of solutions as a string
  String getSolutionsListString() {
    if (pannes == null || pannes!.isEmpty) return "";

    List<String> solutionsList = [];

    for (Panne panne in pannes!) {
      if (panne.solutions != null && panne.solutions!.isNotEmpty) {
        solutionsList.addAll(
            panne.solutions!.map((solution) => solution.name ?? "")
        );
      }
    }

    if (solutionsList.isEmpty) return "";
    return solutionsList.join(", ");
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ref': ref,
      'case_id': caseId,
      'type': type,
      'user_id': userId,
      'prestataire_id': prestataireId,
      'client': client,
      'telephone': telephone,
      'acces_reseau': accesReseau,
      'activites_service': activitesService,
      'type_probleme': typeProbleme,
      'description': description,
      'num_ligne': numLigne,
      'nom_prenom': nomPrenom,
      'num_contact': numContact,
      'adresse': adresse,
      'ville': ville,
      'nom_plan_tarifaire': nomPlanTarifaire,
      'date_incident': dateIncident,
      'situation_abonnement': situationAbonnement,
      'routeur': routeur,
      'power': power,
      'pon': pon,
      'los': los,
      'internet': internet,
      'wifi': wifi,
      'cablage_redemarrage_equipement': cablageRedemarrageEquipement,
      'verification_cablage_pto': verificationCablagePto,
      'plaque_id': plaqueId,
      'date_rdv': dateRdv,
      'longitude': longitude,
      'latitude': latitude,
      'photo_probleme': photoProbleme,
      'photo_signal': photoSignal,
      'photo_resolution_probleme': photoResolutionProbleme,
      'photo_sup1': photoSup1,
      'photo_sup2': photoSup2,
      'commentaire': commentaire,
      'commentaire_sup': commentaireSup,
      'article_id': articleId,
      'adresse_mac': adresseMac,
      'sn_routeur': snRouteur,
      'sn_gpon': snGpon,
      'mac_an_box': macAnBox,
      'sn_an_box': snAnBox,
      'sn_an_gpon': snAnGpon,
      'date_resolution': dateResolution,
      'type_id': typeId,
      'etat_id': etatId,
      'archive_id': archiveId,
      'created': created,
      'etat_name': etatName,
      'plaque_name': plaqueName,
      'login_sip': loginSip,
      'commentaires': commentaires?.map((commentaire) => commentaire.toJson()).toList(),
      'DemandePanne': demandePanne,
      'DemandeSolution': demandeSolution,
      'pannes': pannes?.map((panne) => panne.toJson()).toList(),
    };
  }
}

class Commentaire {
  String? id;
  String? userId;
  String? demandeId;
  String? commentaire;
  String? created;

  Commentaire({
    this.id,
    this.userId,
    this.demandeId,
    this.commentaire,
    this.created,
  });

  factory Commentaire.fromJson(Map<String, dynamic> json) {
    return Commentaire(
      id: json['id'],
      userId: json['user_id'],
      demandeId: json['demande_id'],
      commentaire: json['commentaire'],
      created: json['created'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'demande_id': demandeId,
      'commentaire': commentaire,
      'created': created,
    };
  }
}
