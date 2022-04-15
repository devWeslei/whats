import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/RouteGenerator.dart';
import '../model/Usuario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AbaContatos extends StatefulWidget {
  const AbaContatos({Key? key}) : super(key: key);

  @override
  _AbaContatosState createState() => _AbaContatosState();
}

class _AbaContatosState extends State<AbaContatos> {


  String? _emailUsuarioLogado;


  Future<List<Usuario>> _recuperarContatos() async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    QuerySnapshot querySnapshot = await db.collection("usuarios").get();

    List<Usuario> listaUsuarios = [];
    for (DocumentSnapshot item in querySnapshot.docs) {

      dynamic dados = item.data();

      if (dados["email"] == _emailUsuarioLogado) continue;

      Usuario? usuario = Usuario();
      usuario.idUsuario = item.id;
      usuario.email = dados["email"];
      usuario.nome = dados["nome"];
      usuario.urlImagem = dados["UrlImagem"];

      listaUsuarios.add(usuario);
    }

    return listaUsuarios;
  }

  _recuperarDadosUsuario(){
    String? _idUsuarioLogado;

    FirebaseAuth auth = FirebaseAuth.instance;
    User? usuarioLogado = auth.currentUser;
    _idUsuarioLogado = usuarioLogado?.uid;
    _emailUsuarioLogado = usuarioLogado?.email;
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<List<Usuario>>(
      future: _recuperarContatos(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: Column(
                children: [
                  Text("Carregando contatos"),
                  CircularProgressIndicator()
                ],
              ),
            );
          case ConnectionState.active:
          case ConnectionState.done:
            return ListView.builder(
                itemCount: snapshot.data?.length,
                itemBuilder: (_, indice) {
                  List<Usuario?> listaItens = snapshot.data!;
                  Usuario? usuario = listaItens[indice];

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
                        backgroundImage: usuario?.urlImagem != null
                            ? NetworkImage(usuario!.urlImagem!)
                            : null),
                    title: Text(
                      usuario!.nome!,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  );
                });
        }
      },
    );
  }
}
