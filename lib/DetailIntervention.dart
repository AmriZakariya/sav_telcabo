import 'package:flutter/material.dart';
import 'package:telcabo/Tools.dart';
import 'package:telcabo/ui/InterventionHeaderInfoWidget.dart';

class DetailIntervention extends StatefulWidget {
  @override
  State<DetailIntervention> createState() => _DetailInterventionState();
}

class _DetailInterventionState extends State<DetailIntervention> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail'),
        actions: <Widget>[],
      ),
      // endDrawer: EndDrawerWidget(),
      body: Scrollbar(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
                // image: DecorationImage(
                //   image: AssetImage("assets/bg_home.jpeg"),
                //   fit: BoxFit.cover,
                // ),
                color: Tools.colorBackground),
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                  child: InterventionHeaderInfoClientWidget(),
                ),
                SizedBox(
                  height: 20,
                ),
                Divider(
                  color: Colors.black,
                  height: 2,
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                    margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: InterventionHeaderInfoProjectWidget()),
                SizedBox(
                  height: 20,
                ),

                // Container(
                //      height: 500,
                //      child: Expanded(
                //        child: ExpandChild(
                //          child: PhotoViewGallery.builder(
                //            scrollPhysics: const BouncingScrollPhysics(),
                //            builder: (BuildContext context, int index) {
                //              return PhotoViewGalleryPageOptions(
                //                imageProvider: CachedNetworkImageProvider(
                //                    "${Tools.baseUrl}/img/demandes/" +
                //                        (Tools.selectedDemande?.pPbiAvant ?? "")),
                //                initialScale:
                //                    PhotoViewComputedScale.contained * 0.8,
                //                heroAttributes:
                //                    PhotoViewHeroAttributes(tag: "pPbiAvant"),
                //              );
                //            },
                //            itemCount: 4,
                //            loadingBuilder: (context, event) => Center(
                //              child: Container(
                //                width: 20.0,
                //                height: 20.0,
                //                child: CircularProgressIndicator(
                //                  value: event == null
                //                      ? 0
                //                      : (event.cumulativeBytesLoaded /
                //                              (event.expectedTotalBytes ?? 1)) ??
                //                          0,
                //                ),
                //              ),
                //            ),
                //            // backgroundDecoration: widget.backgroundDecoration,
                //            // pageController: widget.pageController,
                //            // onPageChanged: onPageChanged,
                //          ),
                //        ),
                //      ))

                InterventionInformationWidget(),
                SizedBox(
                  height: 20,
                ),

                InterventionHeaderImagesWidget(),
                SizedBox(
                  height: 20,
                ),
                // MapSample(),
                SizedBox(
                  height: 20,
                ),

                HeaderCommentaireWidget(),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
