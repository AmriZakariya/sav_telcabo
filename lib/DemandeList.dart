import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:dartx/dartx.dart';
import 'package:expand_widget/expand_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:telcabo/Annulation.dart';
import 'package:telcabo/DetailIntervention.dart';
import 'package:telcabo/Intervention.dart';
import 'package:telcabo/NotificationExample.dart';
import 'package:telcabo/Planification.dart';
import 'package:telcabo/Tools.dart';
import 'package:telcabo/custome/ConnectivityCheckBlocBuilder.dart';
import 'package:telcabo/models/response_get_demandes.dart';
import 'package:telcabo/ui/DrawerWidget.dart';
import 'package:telcabo/ui/InterventionHeaderInfoWidget.dart';
import 'package:telcabo/ui/LoadingDialog.dart';
import 'package:url_launcher/url_launcher.dart';

final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

class DemandeList extends StatefulWidget {
  @override
  State<DemandeList> createState() => _DemandeListState();
}

class _DemandeListState extends State<DemandeList> with WidgetsBindingObserver {
  final _scrollController = ScrollController();

  // late ResponseGetDemandesList demandesList;
  final _formKey = GlobalKey<FormBuilderState>();

  GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  ResponseGetDemandesList? demandesList;
  Future<void>? _initDemandesData;

  TextEditingController _searchController = TextEditingController();

  late NavigatorState navigator;

  @override
  void didChangeDependencies() {
    navigator = Navigator.of(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("didChangeAppLifecycleState state ==> ${state}");
    // if (state == AppLifecycleState.resumed) {
    //   filterListByMap();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Tools.colorPrimary,
      drawer: DrawerWidget(),
      endDrawer: EndDrawerFilterWidget(),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {  },
      //   child: Icon(Icons.info),
      //
      // ),
      onEndDrawerChanged: (isOpened) {
        if (!isOpened) {
          filterListByMap();
        }
      },
      onDrawerChanged: (isOpened) {
        if (!isOpened) {
          filterByType();
        }
      },
      body: MultiBlocProvider(
        providers: [
          BlocProvider<InterventionFormBLoc>(
            create: (BuildContext context) => InterventionFormBLoc(),
          ),
          BlocProvider<PlanificationFormBloc>(
            create: (BuildContext context) => PlanificationFormBloc(),
          ),
          BlocProvider<InternetCubit>(
            create: (BuildContext context) =>
                InternetCubit(connectivity: Connectivity()),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<InternetCubit, InternetState>(
              listenWhen: (previous, current) {
                print("**** buildWhen *** ");
                print("previous ==>  ${previous} ");
                print("current ==>  ${current} ");
                return previous != current;
              },
              listener: (context, state) async {
                if (state is InternetConnected) {
                  print("InternetConnected");
                  showSimpleNotification(
                      Text("status : en ligne , synchronisation en cours "),
                      // subtitle: Text("onlime"),
                      background: Colors.green,
                      duration: Duration(seconds: 5),
                      position: NotificationPosition.bottom);

                  await Tools.readFileTraitementList();

                  final items = await Tools.getDemandes();

                  setState(() {
                    Tools.demandesListSaved = items;
                    demandesList = items;
                  });
                }
                if (state is InternetDisconnected) {
                  // showSimpleNotification(
                  //   Text("Offline"),
                  //   // subtitle: Text("onlime"),
                  //   background: Colors.red,
                  //   duration: Duration(seconds: 5),
                  // );
                }
              },
            ),
          ],
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                controller: _scrollController,
                // <---- Same as the Scrollbar controller

                // padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 50.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            TextButton.icon(
                              icon: Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 25,
                              ),
                              label: Container(
                                child: Row(
                                  children: [
                                    Container(
                                      width: MediaQuery
                                          .of(context)
                                          .size
                                          .width -
                                          200,
                                      child: Text(
                                        getTitleText(),
                                        overflow: TextOverflow.ellipsis,
                                        // default is .clip
                                        maxLines: 2,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showDemandesDialog(context);
                                      },
                                      child: Tooltip(
                                        message: "Detail",
                                        child: Container(
                                          padding:
                                          const EdgeInsets.only(top: 3),
                                          width: 35,
                                          height: 35,
                                          decoration: BoxDecoration(
                                              color: Tools.colorPrimary,
                                              shape: BoxShape.circle),
                                          child: Center(
                                              child: FaIcon(
                                                FontAwesomeIcons.circleInfo,
                                                color: Colors.white,
                                                size: 20,
                                              )),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onPressed: () {
                                // Navigator.pop(context);
                                scaffoldKey.currentState!.openDrawer();
                              },
                            ),
                          ],
                        ),
                        IconButton(
                          color: Colors.white,
                          iconSize: 28,
                          icon: const Icon(Icons.filter_list),
                          onPressed: () async {
                            scaffoldKey.currentState?.openEndDrawer();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    Container(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height - 140.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.only(topLeft: Radius.circular(75.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(children: <Widget>[
                          Expanded(
                            child: Container(
                              height: MediaQuery
                                  .of(context)
                                  .size
                                  .height,
                              child: FutureBuilder(
                                future: _initDemandesData,
                                builder: (BuildContext context, snapshot) {
                                  switch (snapshot.connectionState) {
                                    case ConnectionState.none:
                                    case ConnectionState.waiting:
                                    case ConnectionState.active:
                                      {
                                        return LoadingWidget();
                                      }
                                    case ConnectionState.done:
                                      {
                                        return RefreshIndicator(
                                            key: _refreshIndicatorKey,
                                            displacement: 0,
                                            onRefresh: _refreshList,
                                            child: Scrollbar(
                                              child: ListView.builder(
                                                itemCount: demandesList
                                                    ?.demandes?.length ??
                                                    0,
                                                itemBuilder:
                                                    (BuildContext context,
                                                    index) {
                                                  final item = demandesList
                                                      ?.demandes?[index];

                                                  final Demande demande = item!;
                                                  return Padding(
                                                      padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8),
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                            .only(left: 15),
                                                        decoration:
                                                        BoxDecoration(
                                                            border:
                                                            Border.all(
                                                              color: Colors
                                                                  .transparent,
                                                              // style: BorderStyle.values
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Tools
                                                                    .getColorByEtatId(
                                                                    demande
                                                                        .etatId)
                                                                    .withOpacity(
                                                                    0.5),
                                                                spreadRadius:
                                                                1,
                                                                blurRadius:
                                                                1,
                                                                offset: Offset(
                                                                    0,
                                                                    0), // changes position of shadow
                                                              ),
                                                            ],
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                20) // use instead of BorderRadius.all(Radius.circular(20))
                                                        ),
                                                        child: Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                              children: [
                                                                Container(
                                                                  width: double
                                                                      .infinity,
                                                                  height: 65,
                                                                  decoration:
                                                                  BoxDecoration(
                                                                      color: Tools
                                                                          .getColorByEtatId(
                                                                          demande
                                                                              .etatId),
                                                                      border:
                                                                      Border
                                                                          .all(
                                                                        color: Colors
                                                                            .transparent,
                                                                      ),
                                                                      borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                          20) // use instead of BorderRadius.all(Radius.circular(20))
                                                                  ),
                                                                  child: Row(
                                                                      children: [
                                                                        SizedBox(
                                                                          height:
                                                                          5.0,
                                                                        ),
                                                                        // CircleAvatar(
                                                                        //   radius: 32.0,
                                                                        //   backgroundImage: AssetImage('assets/user.png'),
                                                                        //   backgroundColor: Colors.white,
                                                                        // ),
                                                                        Padding(
                                                                          padding: const EdgeInsets
                                                                              .only(
                                                                              left:
                                                                              8),
                                                                          child:
                                                                          Icon(
                                                                            Icons
                                                                                .person,
                                                                            size:
                                                                            22,
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          width: MediaQuery
                                                                              .of(
                                                                              context)
                                                                              .size
                                                                              .width -
                                                                              175,
                                                                          child: Text(
                                                                              '${demande
                                                                                  .client}',
                                                                              overflow: TextOverflow
                                                                                  .ellipsis,
                                                                              style:
                                                                              TextStyle(
                                                                                color:
                                                                                Colors
                                                                                    .black,
                                                                                fontSize:
                                                                                16.0,
                                                                              )),
                                                                        ),

                                                                        // Spacer(),
                                                                        Row(
                                                                          mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                          mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .end,
                                                                          children: [
                                                                            GestureDetector(
                                                                              onTap:
                                                                                  () {
                                                                                Tools
                                                                                    .selectedDemande =
                                                                                    demande;
                                                                                Tools
                                                                                    .currentStep =
                                                                                    (Tools
                                                                                        .selectedDemande
                                                                                        ?.etape ??
                                                                                        1) -
                                                                                        1;
                                                                                print(
                                                                                    "currentStepValueNotifier updateValue => ${Tools
                                                                                        .currentStep} ");
                                                                                currentStepValueNotifier
                                                                                    .value =
                                                                                    Tools
                                                                                        .currentStep;

                                                                                print(
                                                                                    "Tools.selectedDemande => ${Tools
                                                                                        .selectedDemande
                                                                                        ?.toJson()}");

                                                                                navigator
                                                                                    .push(
                                                                                    MaterialPageRoute(
                                                                                      builder: (
                                                                                          _) =>
                                                                                          DetailIntervention(),
                                                                                    ));
                                                                              },
                                                                              child:
                                                                              Tooltip(
                                                                                message:
                                                                                "Voir",
                                                                                child:
                                                                                Container(
                                                                                  width: 30,
                                                                                  height: 30,
                                                                                  decoration: BoxDecoration(
                                                                                      color: Tools
                                                                                          .colorPrimary,
                                                                                      shape: BoxShape
                                                                                          .circle),
                                                                                  child: Center(
                                                                                      child: FaIcon(
                                                                                        FontAwesomeIcons
                                                                                            .solidEye,
                                                                                        color: Colors
                                                                                            .white,
                                                                                        size: 15,
                                                                                      )),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            GestureDetector(
                                                                              onTap:
                                                                                  () {
                                                                                Tools
                                                                                    .selectedDemande =
                                                                                    demande;
                                                                                Tools
                                                                                    .currentStep =
                                                                                    (Tools
                                                                                        .selectedDemande
                                                                                        ?.etape ??
                                                                                        1) -
                                                                                        1;
                                                                                print(
                                                                                    "currentStepValueNotifier updateValue => ${Tools
                                                                                        .currentStep} ");
                                                                                currentStepValueNotifier
                                                                                    .value =
                                                                                    Tools
                                                                                        .currentStep;

                                                                                print(
                                                                                    "Tools.selectedDemande => ${Tools
                                                                                        .selectedDemande
                                                                                        ?.toJson()}");

                                                                                navigator
                                                                                    .push(
                                                                                    MaterialPageRoute(
                                                                                      builder: (
                                                                                          _) =>
                                                                                          InterventionForm(),
                                                                                    ))
                                                                                    .then((
                                                                                    _) {
                                                                                  // This method gets callback after your SecondScreen is popped from the stack or finished.
                                                                                  filterListByMap();
                                                                                });
                                                                              },
                                                                              child:
                                                                              Tooltip(
                                                                                message:
                                                                                "Intervention",
                                                                                child:
                                                                                Padding(
                                                                                  padding: const EdgeInsets
                                                                                      .symmetric(
                                                                                      horizontal: 8),
                                                                                  child: Container(
                                                                                    width: 30,
                                                                                    height: 30,
                                                                                    decoration: BoxDecoration(
                                                                                        color: Tools
                                                                                            .colorPrimary,
                                                                                        shape: BoxShape
                                                                                            .circle),
                                                                                    child: Center(
                                                                                        child: FaIcon(
                                                                                          FontAwesomeIcons
                                                                                              .screwdriver,
                                                                                          color: Colors
                                                                                              .white,
                                                                                          size: 15,
                                                                                        )),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            // ElevatedButton(
                                                                            //   child: Icon(Icons.remove_red_eye, size: 20),
                                                                            //   onPressed: () {
                                                                            //     Tools.selectedDemande = demande ;
                                                                            //
                                                                            //   },
                                                                            //   style: ElevatedButton .styleFrom(
                                                                            //     // minimumSize: Size.zero, // Set this
                                                                            //     // padding: EdgeInsets.zero,
                                                                            //     shape: const CircleBorder(),
                                                                            //   ),
                                                                            // ),
                                                                            // ElevatedButton(
                                                                            //   child: FaIcon(FontAwesomeIcons.screwdriver, size: 20),
                                                                            //   onPressed: () {
                                                                            //     Tools.selectedDemande = demande ;
                                                                            //     print("Tools.selectedDemande => ${Tools.selectedDemande?.toJson()}");
                                                                            //
                                                                            //     if(demande.etatId == "3"
                                                                            //         && demande.pPbiAvant != ""
                                                                            //         && demande.pPbiApres != ""){
                                                                            //       // Navigator.of(context).push(MaterialPageRoute(
                                                                            //       //   builder: (_) => InterventionFormStep2(),
                                                                            //       // ));
                                                                            //       Tools.currentStep = 1 ;
                                                                            //     }else{
                                                                            //       // Navigator.of(context).push(MaterialPageRoute(
                                                                            //       //   builder: (_) => InterventionFormStep1(),
                                                                            //       // ));
                                                                            //       Tools.currentStep = 0 ;
                                                                            //
                                                                            //     }
                                                                            //
                                                                            //     // FormBlocState.currentStep = Tools.currentStep ;
                                                                            //
                                                                            //     Navigator.of(context).push(MaterialPageRoute(
                                                                            //       builder: (_) => WizardForm(),
                                                                            //     ));
                                                                            //
                                                                            //   },
                                                                            //   style: ElevatedButton.styleFrom(
                                                                            //     // minimumSize: Size.zero, // Set this
                                                                            //     // padding: EdgeInsets.zero,
                                                                            //     shape: const CircleBorder(),
                                                                            //   ),
                                                                            // ),
                                                                          ],
                                                                        ),
                                                                      ]),
                                                                ),
                                                                ExpandChild(
                                                                  // arrowSize: 25,
                                                                  // arrowPadding: EdgeInsets.all(0),
                                                                  child: Container(
                                                                    // color: Colors.white,
                                                                      child:
                                                                      Padding(
                                                                        padding:
                                                                        EdgeInsets
                                                                            .all(
                                                                            15.0),
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                          children: [
                                                                            // Divider(color: Colors.black, height: 2,),
                                                                            // SizedBox(height: 15,),
                                                                            GestureDetector(
                                                                              onTap:
                                                                                  () {
                                                                                launch(
                                                                                    "tel://${demande
                                                                                        .telephone ??
                                                                                        ""}");
                                                                              },
                                                                              child:
                                                                              InfoItemWidget(
                                                                                iconData:
                                                                                Icons
                                                                                    .phone,
                                                                                title:
                                                                                "Contact Client :",
                                                                                description:
                                                                                demande
                                                                                    .telephone ??
                                                                                    "",
                                                                                iconEnd:
                                                                                Padding(
                                                                                  padding: const EdgeInsets
                                                                                      .only(
                                                                                      right: 5),
                                                                                  child:
                                                                                  FaIcon(
                                                                                    FontAwesomeIcons
                                                                                        .phoneVolume,
                                                                                    size:
                                                                                    22,
                                                                                    color:
                                                                                    Tools
                                                                                        .colorPrimary,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),
                                                                            InfoItemWidget(
                                                                              iconData:
                                                                              Icons
                                                                                  .list,
                                                                              title:
                                                                              "Type :",
                                                                              description:
                                                                              demande
                                                                                  .type ??
                                                                                  "",
                                                                            ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),
                                                                            InfoItemWidget(
                                                                              iconData:
                                                                              Icons
                                                                                  .list,
                                                                              title:
                                                                              "CASE ID : ",
                                                                              description:
                                                                              demande
                                                                                  .caseId ??
                                                                                  "",
                                                                            ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),

                                                                            InfoItemWidget(
                                                                              iconData:
                                                                              Icons
                                                                                  .list,
                                                                              title:
                                                                              "Référence  : ",
                                                                              description:
                                                                              demande
                                                                                  .ref ??
                                                                                  "",
                                                                            ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),
                                                                            InfoItemWidget(
                                                                              iconData:
                                                                              Icons
                                                                                  .list,
                                                                              title:
                                                                              "Description : ",
                                                                              description:
                                                                              demande
                                                                                  .description ??
                                                                                  "",
                                                                            ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),
                                                                            InfoItemWidget(
                                                                              iconData:
                                                                              Icons
                                                                                  .list,
                                                                              title:
                                                                              "Offre tarifaire : ",
                                                                              description:
                                                                              demande
                                                                                  .nomPlanTarifaire ??
                                                                                  "",
                                                                            ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),

                                                                            InfoItemWidget(
                                                                              iconData:
                                                                              Icons
                                                                                  .location_city_sharp,
                                                                              icon:
                                                                              FaIcon(
                                                                                FontAwesomeIcons
                                                                                    .city,
                                                                                size:
                                                                                18,
                                                                              ),
                                                                              title:
                                                                              "Ville :",
                                                                              description:
                                                                              demande
                                                                                  .ville ??
                                                                                  "",
                                                                            ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),

                                                                            InfoItemWidget(
                                                                              iconData:
                                                                              Icons
                                                                                  .list_alt,
                                                                              icon:
                                                                              FaIcon(
                                                                                FontAwesomeIcons
                                                                                    .signHanging,
                                                                                size:
                                                                                18,
                                                                              ),
                                                                              title:
                                                                              "Plaque :",
                                                                              description:
                                                                              demande
                                                                                  .plaqueName ??
                                                                                  "",
                                                                            ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),

                                                                            InfoItemWidget(
                                                                              iconData:
                                                                              Icons
                                                                                  .edit_attributes_sharp,
                                                                              title:
                                                                              "Etat :",
                                                                              description:
                                                                              demande
                                                                                  .etatName ??
                                                                                  "",
                                                                            ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),
                                                                            // InfoItemWidget(
                                                                            //   iconData: Icons.phone_android,
                                                                            //   icon: FaIcon(
                                                                            //     FontAwesomeIcons.sitemap,
                                                                            //     size: 18,
                                                                            //   ),
                                                                            //   title: "Login internet :",
                                                                            //   description: Tools.selectedDemande?.loginInternet ?? "",
                                                                            //   iconEnd:  GestureDetector(
                                                                            //     onTap: () async {
                                                                            //       await Clipboard.setData(ClipboardData(text: Tools.selectedDemande?.loginInternet ?? ""));
                                                                            //     },
                                                                            //     child: Padding(
                                                                            //       padding: const EdgeInsets.only(right: 5),
                                                                            //       child: FaIcon(
                                                                            //         FontAwesomeIcons.copy,
                                                                            //         size: 22,
                                                                            //         color: Tools.colorPrimary,
                                                                            //       ),
                                                                            //     ),
                                                                            //   ),
                                                                            // ),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),
                                                                            Divider(),
                                                                            SizedBox(
                                                                              height:
                                                                              20.0,
                                                                            ),
                                                                            Center(
                                                                              child:
                                                                              Column(
                                                                                mainAxisAlignment:
                                                                                MainAxisAlignment
                                                                                    .center,
                                                                                children: [
                                                                                  DemandeBottomActionButton(
                                                                                      text: "voir",
                                                                                      backgroundColor: Colors.blue,
                                                                                      icon: Icons
                                                                                          .remove_red_eye,
                                                                                      onPressed: () {
                                                                                        Tools
                                                                                            .selectedDemande =
                                                                                            demande;
                                                                                        Tools
                                                                                            .currentStep =
                                                                                            (Tools
                                                                                                .selectedDemande
                                                                                                ?.etape ??
                                                                                                1) -
                                                                                                1;

                                                                                        navigator
                                                                                            .push(
                                                                                            MaterialPageRoute(
                                                                                              builder: (
                                                                                                  _) =>
                                                                                                  DetailIntervention(),
                                                                                            ));
                                                                                      }),
                                                                                  DemandeBottomActionButton(
                                                                                      text: "Planifier",
                                                                                      backgroundColor: Colors.green,
                                                                                      icon: Icons
                                                                                          .date_range,
                                                                                      onPressed: () {
                                                                                        Tools
                                                                                            .selectedDemande =
                                                                                            demande;
                                                                                        Tools
                                                                                            .currentStep =
                                                                                            (Tools
                                                                                                .selectedDemande
                                                                                                ?.etape ??
                                                                                                1) -
                                                                                                1;

                                                                                        navigator
                                                                                            .push(
                                                                                            MaterialPageRoute(
                                                                                              builder: (
                                                                                                  _) =>
                                                                                                  PlanificationForm(),
                                                                                            ));
                                                                                      }),
                                                                                  DemandeBottomActionButton(
                                                                                      text: "Annuler",
                                                                                      backgroundColor: Colors.red,
                                                                                      icon: Icons
                                                                                          .cancel,
                                                                                      onPressed: () {
                                                                                        Tools
                                                                                            .selectedDemande =
                                                                                            demande;
                                                                                        Tools
                                                                                            .currentStep =
                                                                                            (Tools
                                                                                                .selectedDemande
                                                                                                ?.etape ??
                                                                                                1) -
                                                                                                1;

                                                                                        navigator
                                                                                            .push(
                                                                                            MaterialPageRoute(
                                                                                              builder: (
                                                                                                  _) =>
                                                                                                  AnnulationForm(),
                                                                                            ));
                                                                                      }),
                                                                                  DemandeBottomActionButton(
                                                                                      text: "Intervention",
                                                                                      backgroundColor: Colors.teal,
                                                                                      icon: FontAwesomeIcons
                                                                                          .screwdriver,
                                                                                      onPressed: () {
                                                                                        Tools
                                                                                            .selectedDemande =
                                                                                            demande;
                                                                                        Tools
                                                                                            .currentStep =
                                                                                            (Tools
                                                                                                .selectedDemande
                                                                                                ?.etape ??
                                                                                                1) -
                                                                                                1;

                                                                                        navigator
                                                                                            .push(
                                                                                            MaterialPageRoute(
                                                                                              builder: (
                                                                                                  _) =>
                                                                                                  InterventionForm(),
                                                                                            ));
                                                                                      }),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      )),
                                                                ),
                                                                SizedBox(
                                                                  height: 5.0,
                                                                ),
                                                              ],
                                                            )),
                                                      ));
                                                },
                                              ),
                                            ));
                                      }
                                  }
                                },
                              ),
                              // FutureBuilder<ResponseGetDemandesList>(
                              //   future: Tools.getListDemandeFromLocalAndINternet(),
                              //   builder: (BuildContext context, AsyncSnapshot<ResponseGetDemandesList> snapshot) {
                              //     List<Widget> children;
                              //     if (snapshot.hasData) {
                              //       return RefreshIndicator(
                              //         onRefresh: () async {
                              //           refreshDemandeList();
                              //         },
                              //         child: Scrollbar(
                              //           isAlwaysShown: true,
                              //           child: ListView.builder(
                              //             // Let the ListView know how many items it needs to build.
                              //             itemCount: snapshot.data?.demandes?.length  ?? 0,
                              //             // Provide a builder function. This is where the magic happens.
                              //             // Convert each item into a widget based on the type of item it is.
                              //             itemBuilder: (context, index) {
                              //               final item = snapshot.data?.demandes?[index];
                              //
                              //               return Padding(
                              //                 padding: const EdgeInsets.only(bottom: 8),
                              //                 child: DemandeListItem(demande: item!,),
                              //               );
                              //             },),
                              //         ),
                              //       );
                              //     } else if (snapshot.hasError) {
                              //       return Center(
                              //         child: Column(
                              //           mainAxisAlignment: MainAxisAlignment.center,
                              //           children: [
                              //             Icon(
                              //               Icons.error_outline,
                              //               color: Colors.red,
                              //               size: 60,
                              //             ),
                              //             Padding(
                              //               padding: const EdgeInsets.only(top: 16),
                              //               child: Text('Error: ${snapshot.error}'),
                              //             )
                              //           ],
                              //         ),
                              //       );
                              //
                              //     } else {
                              //       return Center(
                              //         child: Column(
                              //           mainAxisAlignment: MainAxisAlignment.center,
                              //           children: [
                              //             SizedBox(
                              //               width: 60,
                              //               height: 60,
                              //               child: CircularProgressIndicator(),
                              //             ),
                              //             Padding(
                              //               padding: EdgeInsets.only(top: 16),
                              //               child: Text('résultat en attente...'),
                              //             )
                              //           ],
                              //         ),
                              //       );
                              //
                              //     }
                              //
                              //   },
                              // ),
                            ),
                          ),
                        ]),
                      ),
                    )
                  ],
                ),
              ),
              BlocBuilder<InternetCubit, InternetState>(
                buildWhen: (previous, current) {
                  print("**** buildWhen *** ");
                  print("previous ==>  ${previous} ");
                  print("current ==>  ${current} ");
                  return previous != current;
                },
                builder: (context, state) {
                  print("BlocBuilder **** InternetCubit ${state}");
                  if (state is InternetConnected &&
                      state.connectionType == ConnectionType.wifi) {
                    // return Text(
                    //   'Wifi',
                    //   style: TextStyle(color: Colors.green, fontSize: 30),
                    // );
                  } else if (state is InternetConnected &&
                      state.connectionType == ConnectionType.mobile) {
                    // return Text(
                    //   'Mobile',
                    //   style: TextStyle(color: Colors.yellow, fontSize: 30),
                    // );
                  } else if (state is InternetDisconnected) {
                    return Positioned(
                      bottom: 0,
                      child: Center(
                        child: Container(
                          color: Colors.grey.shade400,
                          width: MediaQuery
                              .of(context)
                              .size
                              .width,
                          padding: const EdgeInsets.all(0.0),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Pas d'accès internet",
                                style:
                                TextStyle(color: Colors.red, fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  // return CircularProgressIndicator();
                  return Container();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
    // Tools.getDemandes();
    final items = await Tools.getDemandes();

    setState(() {
      Tools.demandesListSaved = items;
      demandesList = items;
    });
  }

  late final FirebaseMessaging _messaging;
  PushNotification? _notificationInfo;

  void registerNotification() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // String deviceToken = "" ;
    // await _messaging.getToken().then((value) {
    //   print("Device Token ${value}");
    //   deviceToken = value ?? "" ;
    // });
    //
    // Tools.deviceToken = deviceToken;
    // print("registerNotification "+ Tools.deviceToken );

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print(
            'Message title: ${message.notification?.title}, body: ${message
                .notification?.body}, data: ${message.data}');

        // Parse the message received
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          dataTitle: message.data['title'],
          dataBody: message.data['body'],
        );

        final items = await Tools.getDemandes();

        setState(() {
          Tools.demandesListSaved = items;
          demandesList = items;
        });

        if (_notificationInfo != null) {
          // For displaying the notification as an overlay
          showSimpleNotification(
            Text(_notificationInfo!.title!),
            leading: NotificationBadge(totalNotifications: 100),
            subtitle: Text(_notificationInfo!.body!),
            background: Colors.cyan.shade700,
            duration: Duration(seconds: 2),
          );
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("*** FirebaseMessaging.instance.getInitialMessage() ***");

      PushNotification notification = PushNotification(
        title: initialMessage.notification?.title,
        body: initialMessage.notification?.body,
        dataTitle: initialMessage.data['title'],
        dataBody: initialMessage.data['body'],
      );

      // Tools.getDemandes();

      final items = await Tools.getDemandes();

      setState(() {
        Tools.demandesListSaved = items;
        demandesList = items;
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("*** onMessageOpenedApp ***");

      PushNotification notification = PushNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        dataTitle: message.data['title'],
        dataBody: message.data['body'],
      );

      // Tools.getDemandes();
      final items = await Tools.getDemandes();

      setState(() {
        Tools.demandesListSaved = items;
        demandesList = items;
      });
    });
  }

  @override
  void initState() {
    // WidgetsBinding.instance.addObserver(this);
    super.initState();
    Tools.getDemandes();

    _initDemandesData = _initList();

    registerNotification();
    checkForInitialMessage();

    Tools.readFileTraitementList();
  }

  Future<void> _initList() async {
    final items = await Tools.getListDemandeFromLocalAndINternet();
    setState(() {
      Tools.demandesListSaved = items;
      demandesList = items;
    });
  }

  Future<void> _refreshList() async {
    var items = await Tools.getListDemandeFromLocalAndINternet();
    Tools.demandesListSaved = items;

    if (Tools.currentDemandesEtatFilter.isNotEmpty) {
      items = ResponseGetDemandesList(
          demandes: Tools.demandesListSaved?.demandes?.where((element) {
            return element.etatId == Tools.currentDemandesEtatFilter;
          }).toList());
    }
    filterListByMap();
  }

  Future<void> filterListByCLient(String client) async {
    final items = ResponseGetDemandesList(
        demandes: Tools.demandesListSaved?.demandes?.where((element) {
          print("check ${element.client}");
          return element.client?.toLowerCase().contains(client.toLowerCase()) ??
              false;
        }).toList());
    setState(() {
      demandesList = items;
    });
  }

  Future<void> filterListByMap() async {
    print("call function filterListByMap()");
    String filter_client = Tools.searchFilter?["client"] ?? "";
    String filter_contactClient = Tools.searchFilter?["contactClient"] ?? "";

    final items = ResponseGetDemandesList(
        demandes: Tools.demandesListSaved?.demandes?.where((element) {
          print("check ${element.client}");

          bool shouldAdd = true;

          if (Tools.currentDemandesEtatFilter.isNotEmpty) {
            shouldAdd = (Tools.currentDemandesEtatFilter == element.etatId);
          }

          if (filter_client.isNotNullOrEmpty) {
            if (element.client
                ?.toLowerCase()
                .contains(filter_client.toLowerCase()) ??
                false) {} else {
              shouldAdd = false;
            }
          }

          if (filter_contactClient.isNotNullOrEmpty) {
            if (element.telephone
                ?.toLowerCase()
                .contains(filter_contactClient.toLowerCase()) ??
                false) {} else {
              shouldAdd = false;
            }
          }

          return shouldAdd;
        }).toList());

    setState(() {
      demandesList = items;
    });
  }

  Future<void> filterByType() async {
    final items = ResponseGetDemandesList(
        demandes: Tools.demandesListSaved?.demandes?.where((element) {
          if (Tools.currentDemandesEtatFilter.isNotEmpty) {
            return (Tools.currentDemandesEtatFilter == element.etatId);
          } else {
            return true;
          }
        }).toList());

    // setState(() {
    //   demandesList = items;
    // });

    filterListByMap();
  }

  String getTitleText() {
    if (Tools.currentDemandesEtatFilter.isNotEmpty) {
      String currentFilterEtatName = "";
      if (Tools.currentDemandesEtatFilter == Tools.ETAT_EN_COURS) {
        currentFilterEtatName = "en cours";
      } else if (Tools.currentDemandesEtatFilter == Tools.ETAT_PLANIFIE) {
        currentFilterEtatName = "planifiées";
      } else if (Tools.currentDemandesEtatFilter == Tools.ETAT_RESOLU) {
        currentFilterEtatName = "résolues";
      } else if (Tools.currentDemandesEtatFilter == Tools.ETAT_ANNULE) {
        currentFilterEtatName = "annulées";
      }
      return " Demandes ${currentFilterEtatName} (${Tools.demandesListSaved
          ?.demandes?.where((element) {
        return (Tools.currentDemandesEtatFilter == element.etatId);
      }).length})";
    }

    return "Liste demandes (${Tools.demandesListSaved?.demandes?.length ?? 0})";
  }

  void showDemandesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Demandes Information',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Open Sans',
              letterSpacing: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  color: Colors.white,
                  thickness: 1,
                ),
                _buildInfoRow(
                  title: 'Demandes disponibles',
                  value: "${Tools.demandesListSaved?.demandes?.length ?? 0}",
                ),
                _buildInfoRow(
                  title: 'Demandes en cours',
                  value:
                  "${Tools.demandesListSaved?.demandes
                      ?.where((element) =>
                  element.etatId == Tools.ETAT_EN_COURS)
                      .length ?? 0}",
                ),
                _buildInfoRow(
                  title: 'Demandes planifiées',
                  value:
                  "${Tools.demandesListSaved?.demandes
                      ?.where((element) =>
                  element.etatId == Tools.ETAT_PLANIFIE)
                      .length ?? 0}",
                ),
                _buildInfoRow(
                  title: 'Demandes résolues',
                  value:
                  "${Tools.demandesListSaved?.demandes
                      ?.where((element) => element.etatId == Tools.ETAT_RESOLU)
                      .length ?? 0}",
                ),
                _buildInfoRow(
                  title: 'Demandes annulées',
                  value:
                  "${Tools.demandesListSaved?.demandes
                      ?.where((element) => element.etatId == Tools.ETAT_ANNULE)
                      .length ?? 0}",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Quitter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Open Sans',
                letterSpacing: 1.1,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.lightGreenAccent,
              fontWeight: FontWeight.bold,
              fontFamily: 'Open Sans',
              letterSpacing: 1.1,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class DemandeBottomActionButton extends StatelessWidget {
  const DemandeBottomActionButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
  }) : super(key: key);

  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Center(child: Icon(icon, size: 20)),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(10, 10),
            shape: const CircleBorder(),
          ),
        ),
        Text(text)
      ],
    );
  }
}

class EndDrawerFilterWidget extends StatelessWidget {
  const EndDrawerFilterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            // image: DecorationImage(
            //   image: AssetImage("assets/bg_home.jpeg"),
            //   fit: BoxFit.cover,
            // ),
              color: Tools.colorBackground),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Text("Filter"),
                SearchFieldFormWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchFIeldsFormBloc extends FormBloc<String, String> {
  final client = TextFieldBloc(
      name: "client", initialValue: Tools.searchFilter?["client"] ?? "");

  // final offre = TextFieldBloc(
  //     name: "offre", initialValue: Tools.searchFilter?["offre"] ?? "");
  final typeDemande = TextFieldBloc(
      name: "typeDemande",
      initialValue: Tools.searchFilter?["typeDemande"] ?? "");
  final contactClient = TextFieldBloc(
      name: "contactClient",
      initialValue: Tools.searchFilter?["contactClient"] ?? "");

  SearchFIeldsFormBloc() : super() {
    addFieldBlocs(fieldBlocs: [
      client,
      typeDemande,
      contactClient,
    ]);
  }

  @override
  void onSubmitting() async {
    print("onSubmitting async");

    try {
      Map<String, dynamic> jsonResult = state.toJson();
      print("jsonResult ==> ${jsonResult}");
      Tools.searchFilter = jsonResult;
      emitSuccess(canSubmitAgain: true);
    } catch (e) {
      emitFailure();
    }
  }
}

class SearchFieldFormWidget extends StatelessWidget {
  const SearchFieldFormWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      child: BlocProvider(
        create: (context) => SearchFIeldsFormBloc(),
        child: Builder(
          builder: (context) {
            final formBloc = BlocProvider.of<SearchFIeldsFormBloc>(context);

            return FormBlocListener<SearchFIeldsFormBloc, String, String>(
              onSubmitting: (context, state) {
                print(" SearchFieldFormWidget onSubmitting");

                LoadingDialog.show(context);
              },
              onSuccess: (context, state) {
                print(" SearchFieldFormWidget onSuccess");

                LoadingDialog.hide(context);

                // Navigator.of(context).pushReplacement(
                //     MaterialPageRoute(builder: (_) => const SuccessScreen()));

                Navigator.of(context).pop();

                // filterListByCLient(_searchController.value.text);
              },
              onFailure: (context, state) {
                print(" SearchFieldFormWidget onFailure");

                LoadingDialog.hide(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.failureResponse!)));
              },
              onSubmissionFailed: (context, state) {
                print(" SearchFieldFormWidget onSubmissionFailed " +
                    state.toString());

                LoadingDialog.hide(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("onSubmissionFailed")));
              },
              child: ScrollableFormBlocManager(
                formBloc: formBloc,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: <Widget>[
                      TextFieldBlocBuilder(
                        textFieldBloc: formBloc.client,
                        decoration: const InputDecoration(
                          labelText: 'Client',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(top: 10, left: 12),
                            child: FaIcon(
                              FontAwesomeIcons.solidUser,
                            ),
                          ),
                        ),
                      ),
                      TextFieldBlocBuilder(
                        textFieldBloc: formBloc.typeDemande,
                        decoration: const InputDecoration(
                          labelText: 'Type demande ',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(top: 10, left: 12),
                            child: FaIcon(
                              FontAwesomeIcons.tag,
                              // size: 18,
                            ),
                          ),
                        ),
                      ),
                      TextFieldBlocBuilder(
                        textFieldBloc: formBloc.contactClient,
                        decoration: const InputDecoration(
                          labelText: 'Contact Client',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(top: 10, left: 12),
                            child: FaIcon(
                              FontAwesomeIcons.phone,
                              // size: 18,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.filter_list,
                            size: 24.0,
                          ),
                          onPressed: () {
                            print("cliick");
                            // formBloc.readJson();
                            // formBloc.fileTraitementList.writeAsStringSync("");

                            formBloc.submit();
                          },
                          label: const Text(
                            'Filtrer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18.0,
                              wordSpacing: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            // shape: CircleBorder(),

                            minimumSize: Size(280, 50),
                            // primary: Tools.colorPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
