
import 'package:equatable/equatable.dart';

class TraitementList {
  List<Traitement>? traitementList;

  TraitementList({this.traitementList});

  TraitementList.fromJson(Map<String, dynamic> json) {
    if (json['traitementList'] != null) {
      traitementList = <Traitement>[];
      json['traitementList'].forEach((v) {
        traitementList!.add(new Traitement.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.traitementList != null) {
      data['traitementList'] = this.traitementList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Traitement extends Equatable {
  String? id;
  String? name;

  Traitement.fromJson(Map<String, dynamic> json) {


  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    // if (this.traitementList != null) {
    //   data['traitementList'] = this.traitementList!.map((v) => v.toJson()).toList();
    // }
    return data;
  }

  @override
  List<Object?> get props =>[];

}