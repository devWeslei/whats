import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'model/Conversa.dart';
import 'model/Mensagem.dart';
import 'model/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class Mensagens extends StatefulWidget {
   final Usuario contato;
  Mensagens(this.contato);

  @override
  _MensagensState createState() => _MensagensState();
}

class _MensagensState extends State<Mensagens> {
  Usuario _usuarioLogado = Usuario();
  bool _subindoImagem = false;
  String? _idUsuarioLogado;
  String? _idUsuarioDestinatario;
  FirebaseFirestore db = FirebaseFirestore.instance;

  TextEditingController _controllerMensagem = TextEditingController();
  ScrollController _scrollController = ScrollController();

  final _controller = StreamController<QuerySnapshot>.broadcast();


  _enviarMensagem() {
    String? textoMensagem = _controllerMensagem.text;
    if (textoMensagem.isNotEmpty) {
      Mensagem? mensagem = Mensagem();
      mensagem.idUsuario = _idUsuarioLogado;
      mensagem.mensagem = textoMensagem;
      mensagem.urlImagem = "";
      mensagem.data = Timestamp.now().toString();
      mensagem.tipo = "texto";

      //Salvar mensagem para remetente
      _salvarMensagem(_idUsuarioLogado!, _idUsuarioDestinatario!, mensagem);

      //Salvar mensagem para destinatario
      _salvarMensagem(_idUsuarioDestinatario!, _idUsuarioLogado!, mensagem);

      //Salvar conversa
      _salvarCoversa(mensagem);
    }
  }

  _salvarCoversa(Mensagem msg) {
    //Salvar conversa remetente
    Conversa cRemetente = Conversa();
    cRemetente.idRemetente = _idUsuarioLogado;
    cRemetente.idDestinatario = _idUsuarioDestinatario;
    cRemetente.mensagem = msg.mensagem;
    cRemetente.nome = widget.contato.nome;
    cRemetente.caminhoFoto = widget.contato.urlImagem;
    cRemetente.tipoMensagem = msg.tipo;
    cRemetente.salvar();

    //Salvar conversa destinatario
    Conversa cDestinatario = Conversa();
    cDestinatario.idRemetente = _idUsuarioDestinatario;
    cDestinatario.idDestinatario = _idUsuarioLogado;
    cDestinatario.mensagem = msg.mensagem;
    cDestinatario.nome = _usuarioLogado.nome;
    cDestinatario.caminhoFoto = _usuarioLogado.urlImagem;
    cDestinatario.tipoMensagem = msg.tipo;
    cDestinatario.salvar();
  }

  _salvarMensagem(
      String idRemetente, String idDestinatario, Mensagem msg) async {
    await db
        .collection("mensagens")
        .doc(idRemetente)
        .collection(idDestinatario)
        .add(msg.toMap());

    //Limpa texto
    _controllerMensagem.clear();
  }

  final ImagePicker _picker = ImagePicker();
  _enviarFoto() async {
    XFile? imagemSelecionada;
    imagemSelecionada = await _picker.pickImage(source: ImageSource.gallery);

    _subindoImagem = true;
    String nomeImagem = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference pastaRaiz = storage.ref();
    Reference arquivo = pastaRaiz
        .child("mensagens")
        .child(_idUsuarioLogado!)
        .child(nomeImagem + ".jpg");

    //Upload da imagem
    File file = File(imagemSelecionada!.path);

    UploadTask task = arquivo.putFile(file);

    //Controlar progresso do upload
    task.snapshotEvents.listen((event) {
      if (event.state == TaskState.running) {
        setState(() {
          _subindoImagem = true;
        });
      } else if (event.state == TaskState.success) {
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

    Mensagem mensagem = Mensagem();
    mensagem.idUsuario = _idUsuarioLogado;
    mensagem.mensagem = "";
    mensagem.urlImagem = url;
    mensagem.data = Timestamp.now().toString();
    mensagem.tipo = "imagem";

    //Salvar mensagem para remetente
    _salvarMensagem(_idUsuarioLogado!, _idUsuarioDestinatario!, mensagem);

    //Salvar mensagem para destinatario
    _salvarMensagem(_idUsuarioDestinatario!, _idUsuarioLogado!, mensagem);

    //Salvar conversa
    _salvarCoversa(mensagem);
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User usuarioLogado = auth.currentUser!;

    DocumentSnapshot snapshot =
        await db.collection("usuarios").doc(usuarioLogado.uid).get();

    dynamic user = snapshot.data();


     _idUsuarioLogado = usuarioLogado.uid;
     _idUsuarioDestinatario = widget.contato.idUsuario!;

    _adicionarListenerMensagens();

    setState((){
      _idUsuarioLogado = usuarioLogado.uid;
      _idUsuarioDestinatario = widget.contato.idUsuario!;
      _usuarioLogado.nome = user["nome"];
      _usuarioLogado.urlImagem = user["UrlImagem"];
      _usuarioLogado.email = usuarioLogado.email;
    });
  }

  Stream<QuerySnapshot>? _adicionarListenerMensagens(){

    final stream = db.collection("mensagens")
        .doc(_idUsuarioLogado)
        .collection(widget.contato.idUsuario!)
    .orderBy("data" , descending: false) // descendente: ( de A a Z e de 0 a 9)
        .snapshots();

    stream.listen((dados) {
      _controller.add( dados );
      Timer(Duration(seconds: 1), (){
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
    return null;

  }


  @override
  void initState(){
     super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    var caixaMensagem = Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: TextField(
                controller: _controllerMensagem,
                //autofocus: true,
                keyboardType: TextInputType.text,
                style: TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(32, 8, 32, 8),
                  hintText: "Digite uma mensagem...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  prefixIcon: _subindoImagem
                      ? CircularProgressIndicator()
                      : IconButton(
                          onPressed: _enviarFoto,
                          icon: Icon(Icons.camera_alt),
                        ),
                ),
              ),
            ),
          ),
          Platform.isIOS
          ? CupertinoButton(
              child: Text("Enviar"),
              onPressed: _enviarMensagem,
          )
          : FloatingActionButton(
            backgroundColor: Color(0xff075E54),
            child: Icon(
              Icons.send,
              color: Colors.white,
            ),
            mini: true,
            onPressed: _enviarMensagem,
          ),
        ],
      ),
    );

    var stream = StreamBuilder(
      stream: _controller.stream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: Column(
                children: [
                  Text("Carregando mensagens"),
                  CircularProgressIndicator()
                ],
              ),
            );
          case ConnectionState.active:
          case ConnectionState.done:
            QuerySnapshot querySnapshot =
                snapshot.data as QuerySnapshot<Object?>;
            print("Usuario Logado: " + _idUsuarioLogado!);
            print("QuerySnapshot: " + querySnapshot.docs.length.toString());
            print("snapshot.data: " + snapshot.data.toString());

            if (snapshot.hasError) {
              return Text("Erro ao carregar os dados!");
            } else {
              return Expanded(
                  child: ListView.builder(
                      controller: _scrollController,
                      itemCount: querySnapshot.docs.length,
                      itemBuilder: (context, indice) {
                        //recupera mensagem
                        List<DocumentSnapshot> mensagens =
                            querySnapshot.docs.toList();
                        DocumentSnapshot item = mensagens[indice];

                        double larguraContainer =
                            MediaQuery.of(context).size.width * 0.8;

                        //define cores e alinhamentos
                        Alignment alinhamento = Alignment.centerRight;
                        Color cor = Color(0xffd2ffa5);
                        if (_idUsuarioLogado != item["idUsuario"]) {
                          alinhamento = Alignment.centerLeft;
                          cor = Colors.white;
                        }

                        return Align(
                          alignment: alinhamento,
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: Container(
                              width: larguraContainer,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: cor,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              child: item["tipo"] == "texto"
                                  ? Text(
                                      item["mensagem"],
                                      style: TextStyle(fontSize: 18),
                                    )
                                  : Image.network(item["urlImagem"]),
                            ),
                          ),
                        );
                      }));
            }
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            CircleAvatar(
                maxRadius: 20,
                backgroundColor: Colors.grey,
                backgroundImage: widget.contato.urlImagem != null
                    ? NetworkImage(widget.contato.urlImagem!)
                    : null),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(widget.contato.nome ?? "sem nome"),
            )
          ],
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("imagens/bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                stream,
                caixaMensagem,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
