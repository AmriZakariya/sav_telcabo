class ResponseGetListType {
  List<Types>? types;

  ResponseGetListType({this.types});

  ResponseGetListType.fromJson(Map<String, dynamic> json) {
    if (json['types'] != null) {
      types = <Types>[];
      json['types'].forEach((v) {
        types!.add(new Types.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.types != null) {
      data['types'] = this.types!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Types {
  String? id;
  String? name;
  List<Motifs>? motifs;

  Types({this.id, this.name, this.motifs});

  Types.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['motifs'] != null) {
      motifs = <Motifs>[];
      json['motifs'].forEach((v) {
        motifs!.add(new Motifs.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    if (this.motifs != null) {
      data['motifs'] = this.motifs!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Motifs {
  String? id;
  String? name;

  Motifs({this.id, this.name});

  Motifs.fromJson(Map<String, dynamic> json) {
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