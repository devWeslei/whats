import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../RouteGenerator.dart';
import '../model/Usuario.dart';

class AbaConversas extends StatefulWidget {
  const AbaConversas({Key? key}) : super(key: key);

  @override
  _AbaConversasState createState() => _AbaConversasState();
}

class _AbaConversasState extends State<AbaConversas> {

  Usuario _usuarioLogado = Usuario();

  final _controller = StreamController<QuerySnapshot>.broadcast();
  FirebaseFirestore db = FirebaseFirestore.instance;
  String? _idUsuarioLogado;

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();

   // Conversa conversa = Conversa();
    //conversa.nome = "Ana Clara";
   // conversa.mensagem = "olá tudo bem?";
   // conversa.caminhoFoto = "https://firebasestorage.googleapis.com/v0/b/whatsapp-74f36.appspot.com/o/perfil%2Fperfil1.jpg?alt=media&token=dec34b0b-93f4-426e-ad68-ef132e6b2047";

   // _listaConversas.add(conversa);
  }

  Stream<QuerySnapshot>? _adicionarListenerConversas(){

    final stream = db.collection("conversas")
        .doc(_idUsuarioLogado)
        .collection("ultima_conversa")
        .snapshots();

    stream.listen((dados) {
      _controller.add( dados );
    });
    return null;

  }

  _recuperarDadosUsuario() async {

    FirebaseAuth auth = FirebaseAuth.instance;
    User usuarioLogado = auth.currentUser!;

    DocumentSnapshot snapshot = await db.collection("usuarios")
        .doc(usuarioLogado.uid).get();

    dynamic user = snapshot.data();

    setState(() {
      _idUsuarioLogado = usuarioLogado.uid;
      _usuarioLogado.nome = user["nome"];
      _usuarioLogado.urlImagem = user["caminhoFoto"];
      _usuarioLogado.email = usuarioLogado.email;
    });

    _adicionarListenerConversas();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(
      stream: _controller.stream,
      builder: (context, snapshot){
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          return Center(
            child: Column(
              children: [
                Text("Carregando conversas"),
                CircularProgressIndicator()
              ],
            ),
          );
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Text("Erro ao carregar os dados!");
            }else{

              QuerySnapshot? querySnapshot = snapshot.data;

              if( querySnapshot?.docs.length == 0){
                return Center(
                  child: Text(
                    "Você não tem nenhuma mensagem ainda :( ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: querySnapshot?.docs.length,
                itemBuilder: (context, indice){

                  List<DocumentSnapshot> conversas = querySnapshot!.docs.toList();
                  DocumentSnapshot item = conversas[indice];

                  String? urlImagem = item["caminhoFoto"];
                  String tipo =  item ["tipoMensagem"];
                  String mensagem = item ["mensagem"];
                  String nome =  item ["nome"];
                  String idDestinatario =  item ["idDestinatario"];

                  Usuario usuario = Usuario();
                  usuario.nome = nome;
                  usuario.urlImagem = urlImagem;
                  usuario.idUsuario = idDestinatario;

                  return ListTile(
                    onTap: (){
                      Navigator.pushNamed(
                        context,
                        RouteGenerator.ROTA_MENSAGENS,
                        arguments: usuario,
                      );
                    },
                    contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    leading: CircleAvatar(
                      maxRadius: 30,
                      backgroundColor: Colors.grey,
                      backgroundImage: urlImagem != null
                        ? NetworkImage( urlImagem )
                        : null,
                    ),
                    title: Text(
                      nome,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(tipo == "texto"
                         ? mensagem
                         : "imagem...",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              );

            }
        }
      },
    );


  }
}
