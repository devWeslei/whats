import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Configuracoes extends StatefulWidget {
  const Configuracoes({Key? key}) : super(key: key);

  @override
  _ConfiguracoesState createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {

  TextEditingController _controllerNome = TextEditingController();
  XFile? _imagem;
  String? _idUsuarioLogado;
  bool _subindoImagem = false;
  String? _urlImagemRecuperada;

  final ImagePicker _picker = ImagePicker();

  Future _recuperarImagem(String origemImagem) async {
    XFile? imagemSelecionada;

    switch (origemImagem) {
      case "camera" :
        imagemSelecionada = await _picker.pickImage(source: ImageSource.camera);
        break;
      case "galeria" :
        imagemSelecionada = await _picker.pickImage(source: ImageSource.gallery);
        break;
    }

    setState(() {
      _imagem = imagemSelecionada;
      if( _imagem != null ){
        _subindoImagem = true;
        _uploadImagem();
      }
    });
  }

  Future _uploadImagem () async {

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference pastaRaiz = storage.ref();
    Reference arquivo = pastaRaiz
     .child("perfil")
     .child(_idUsuarioLogado! + ".jpg");

    //Upload da imagem
    File file = File(_imagem!.path);

    UploadTask task = arquivo.putFile(file);

    //Controlar progresso do upload
    task.snapshotEvents.listen((event) {
      if(event.state == TaskState.running){
        setState(() {
          _subindoImagem = true;
        });
      }else if(event.state == TaskState.success){
        _subindoImagem = false;
      }
    });

    //Recuperando url da imagem
    task.then((TaskSnapshot snapshot) {
      _recuperarUrlImagem(snapshot);
    });
  }

  Future _recuperarUrlImagem(TaskSnapshot snapshot) async {
    String url = await snapshot.ref.getDownloadURL();
    _atualizarUrlImagemFirestore( url );

    setState(() {
      _urlImagemRecuperada = url;
      print("erro" + url);
    });
  }

  _atualizarNomeFirestore(){
    String nome = _controllerNome.text;
    FirebaseFirestore db = FirebaseFirestore.instance;

    Map<String, dynamic> dadosAtualizar = {
      "nome" : nome
    };

    db.collection("usuarios")
        .doc(_idUsuarioLogado)
        .update(dadosAtualizar);

  }

  //lembrando que coloquei UrlImagem com "U" maiusculo.
  _atualizarUrlImagemFirestore( String url){

    FirebaseFirestore db = FirebaseFirestore.instance;

    Map<String, dynamic> dadosAtualizar = {
      "UrlImagem" : url
    };

    db.collection("usuarios")
    .doc(_idUsuarioLogado)
    .update(dadosAtualizar);

  }

  //recuperando imagem e nome de perfil
  _recuperarDadosUsuario() async{

    FirebaseAuth auth = FirebaseAuth.instance;
    User usuarioLogado = await  auth.currentUser!;
    _idUsuarioLogado = usuarioLogado.uid;

    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot snapshot = await db.collection("usuarios")
      .doc(_idUsuarioLogado)
      .get();

    dynamic dados = snapshot.data();

    _controllerNome.text = dados["nome"];

    if(dados["UrlImagem"] != null) {
      setState(() {
        _urlImagemRecuperada = dados["UrlImagem"];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Configurações"),),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: _subindoImagem
                      ? CircularProgressIndicator()
                      : Container(),
                ),
                CircleAvatar(
                  radius: 100,
                  backgroundImage:
                  _urlImagemRecuperada != null
                    ? NetworkImage( _urlImagemRecuperada!)
                    : null,
                  backgroundColor: Colors.grey,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      child: Text("Câmera"),
                      onPressed: (){
                        _recuperarImagem("camera");
                      },
                    ),
                    TextButton(
                      child: Text("Galeria"),
                      onPressed: (){
                        _recuperarImagem("galeria");

                      },
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllerNome,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 20),
                    // onChanged: (texto){
                    //   _atualizarNomeFirestore(texto);
                    // },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Nome",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: ElevatedButton(
                    child: Text(
                      "Salvar",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.green,
                      padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: () {
                      _atualizarNomeFirestore();
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

}
