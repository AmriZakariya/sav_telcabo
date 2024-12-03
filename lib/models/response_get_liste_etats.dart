

class ResponseGetListEtat {
  List<Etat>? etat;

  ResponseGetListEtat({this.etat});

  ResponseGetListEtat.fromJson(Map<String, dynamic> json) {
    if (json['etat'] != null) {
      etat = <Etat>[];
      json['etat'].forEach((v) {
        etat!.add(new Etat.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.etat != null) {
      data['etat'] = this.etat!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}


class Etat {
  String? id;
  String? name;
  List<SousEtat>? sousEtat;

  Etat({this.id, this.name, this.sousEtat});

  Etat.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['sousEtat'] != null) {
      sousEtat = <SousEtat>[];
      json['sousEtat'].forEach((v) {
        sousEtat!.add(new SousEtat.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    if (this.sousEtat != null) {
      data['sousEtat'] = this.sousEtat!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SousEtat {
  String? id;
  String? name;
  List<MotifList>? motifList;

  SousEtat({this.id, this.name, this.motifList});

  SousEtat.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['motifList'] != null) {
      motifList = <MotifList>[];
      json['motifList'].forEach((v) {
        motifList!.add(new MotifList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    if (this.motifList != null) {
      data['motifList'] = this.motifList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MotifList {
  String? id;
  String? name;
  List<Etatimmeubles>? etatimmeubles;

  MotifList({this.id, this.name, this.etatimmeubles});

  MotifList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['etatimmeubles'] != null) {
      etatimmeubles = <Etatimmeubles>[];
      json['etatimmeubles'].forEach((v) {
        etatimmeubles!.add(new Etatimmeubles.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    if (this.etatimmeubles != null) {
      data['etatimmeubles'] =
          this.etatimmeubles!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Etatimmeubles {
  String? id;
  String? name;

  Etatimmeubles({this.id, this.name});

  Etatimmeubles.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }
}