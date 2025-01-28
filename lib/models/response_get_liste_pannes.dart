

import 'dart:ffi';

class ResponseGetListPannes {
  List<Panne>? pannes;

  ResponseGetListPannes({this.pannes});

  ResponseGetListPannes.fromJson(Map<String, dynamic> json) {
    if (json['panne'] != null) {
      pannes = <Panne>[];
      json['panne'].forEach((v) {
        pannes!.add(new Panne.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.pannes != null) {
      data['panne'] = this.pannes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}


class Panne {
  String? id;
  String? name;
  List<Solution>? solutions;

  Panne({this.id, this.name, this.solutions});

  Panne.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'];
    if (json['solutions'] != null) {
      solutions = <Solution>[];
      json['solutions'].forEach((v) {
        solutions!.add(new Solution.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    if (this.solutions != null) {
      data['solutions'] = this.solutions!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  // Override == operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // If the objects are the same reference
    if (other is! Panne) return false; // Ensure the object is of type Panne
    return id == other.id; // Compare based on id
  }

  // Override hashCode
  @override
  int get hashCode => id.hashCode;
}

class Solution {
  String? id;
  String? name;
  bool? hasQuantity = false;
  bool? hasExtra = false;
  List<Article>? articles;
  String? quantity;
  String? articleId;

  Solution({this.id, this.name, this.hasQuantity, this.hasExtra, this.articles, this.quantity, this.articleId});

  Solution.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    hasQuantity = json['has_quantity'];
    hasExtra = json['has_extra'];
    if (json['articles'] != null) {
      articles = <Article>[];
      json['articles'].forEach((v) {
        articles!.add(new Article.fromJson(v));
      });
    }
    quantity = json['quantity'];
    articleId = json['article_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['has_quantity'] = this.hasQuantity;
    data['has_extra'] = this.hasExtra;
    if (this.articles != null) {
      data['articles'] = this.articles!.map((v) => v.toJson()).toList();
    }
    data['quantity'] = this.quantity;
    data['article_id'] = this.articleId;
    return data;
  }

  // Override == operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Solution) return false;
    return id == other.id;
  }

  // Override hashCode
  @override
  int get hashCode => id.hashCode;
}

class Article {
  String? id;
  String? name;

  Article({this.id, this.name});

  Article.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }

  // Override == operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Article) return false;
    return id == other.id;
  }

  // Override hashCode
  @override
  int get hashCode => id.hashCode;
}
