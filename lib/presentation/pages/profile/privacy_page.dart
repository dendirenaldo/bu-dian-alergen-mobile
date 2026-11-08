import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/datasources/contents_remote_datasource.dart';

class _SubSection {
  final String heading;
  final String body;
  const _SubSection(this.heading, this.body);
}

class _Section {
  final String heading;
  final String intro;
  final List<_SubSection> subs;
  const _Section(this.heading, this.intro, this.subs);
}

String _stripTags(String input) {
  var out = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
  out = out
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');
  return out.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<_Section> _parseSections(String body) {
  final h2Re = RegExp(r'<h2[^>]*>(.*?)</h2>', caseSensitive: false, dotAll: true);
  final h3Re = RegExp(r'<h3[^>]*>(.*?)</h3>', caseSensitive: false, dotAll: true);
  final h2Matches = h2Re.allMatches(body).toList();
  if (h2Matches.isNotEmpty) {
    final sections = <_Section>[];
    for (var i = 0; i < h2Matches.length; i++) {
      final start = h2Matches[i].end;
      final end = i + 1 < h2Matches.length ? h2Matches[i + 1].start : body.length;
      final chunk = body.substring(start, end);
      final heading = _stripTags(h2Matches[i].group(1) ?? 'Bagian ${i + 1}');
      final h3Matches = h3Re.allMatches(chunk).toList();
      if (h3Matches.isEmpty) {
        sections.add(_Section(heading, _stripTags(chunk), []));
      } else {
        final intro = _stripTags(chunk.substring(0, h3Matches.first.start));
        final subs = <_SubSection>[];
        for (var j = 0; j < h3Matches.length; j++) {
          final s = h3Matches[j].end;
          final e = j + 1 < h3Matches.length ? h3Matches[j + 1].start : chunk.length;
          subs.add(_SubSection(
            _stripTags(h3Matches[j].group(1) ?? 'Subbagian'),
            _stripTags(chunk.substring(s, e)),
          ));
        }
        sections.add(_Section(heading, intro, subs));
      }
    }
    return sections;
  }

  final lines = body.split('\n');
  final mdSections = <_Section>[];
  var curTitle = '';
  var curBuf = <String>[];
  var curSubs = <_SubSection>[];
  var curSubTitle = '';
  var curSubBuf = <String>[];

  void flushSub() {
    if (curSubTitle.isNotEmpty || curSubBuf.isNotEmpty) {
      curSubs.add(_SubSection(
        curSubTitle.isEmpty ? 'Subbagian' : curSubTitle,
        curSubBuf.join('\n').trim(),
      ));
      curSubTitle = '';
      curSubBuf = [];
    }
  }

  void flushSec() {
    flushSub();
    if (curTitle.isNotEmpty || curBuf.isNotEmpty || curSubs.isNotEmpty) {
      mdSections.add(_Section(
        curTitle.isEmpty ? 'Isi' : curTitle,
        _stripTags(curBuf.join('\n').trim()),
        List.of(curSubs),
      ));
    }
    curTitle = '';
    curBuf = [];
    curSubs = [];
  }

  var hasMdHeading = false;
  for (final line in lines) {
    final t = line.trim();
    if (t.startsWith('## ')) {
      hasMdHeading = true;
      flushSec();
      curTitle = t.substring(3).trim();
    } else if (t.startsWith('### ')) {
      hasMdHeading = true;
      flushSub();
      curSubTitle = t.substring(4).trim();
    } else {
      curBuf.add(line);
      if (curSubTitle.isNotEmpty) curSubBuf.add(line);
    }
  }
  flushSec();
  if (hasMdHeading && mdSections.isNotEmpty) return mdSections;

  final text = _stripTags(body).trim();
  if (text.isEmpty) return [];
  return [_Section('Isi', text, [])];
}

const String _fallbackPrivacyBody = '''
<h2>1. Data yang Kami Kumpulkan</h2>
<p>Kami mengumpulkan email, nama, dan gambar label makanan yang Anda unggah untuk keperluan deteksi alergen.</p>
<h3>Data Akun</h3>
<p>Nama, email, dan kredensial terenkripsi untuk autentikasi.</p>
<h2>2. Penggunaan Data</h2>
<p>Data dipakai untuk menjalankan deteksi, menyimpan riwayat, dan meningkatkan kualitas model.</p>
<h2>3. Penyimpanan & Keamanan</h2>
<p>Data disimpan dengan akses terbatas dan token sesi. Kami menerapkan praktik keamanan yang wajar.</p>
<h2>4. Hak Pengguna</h2>
<p>Anda dapat meminta akses, koreksi, atau penghapusan data melalui pengaturan akun.</p>
<h2>5. Kontak</h2>
<p>Hubungi pengelola aplikasi untuk pertanyaan terkait privasi data Anda.</p>
''';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  static const _cacheKey = 'contents_privacy';
  final _dataSource = ContentsRemoteDataSource();
  bool _loading = true;
  bool _disposed = false;
  String _title = 'Kebijakan Privasi';
  String _body = '';
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          final map = jsonDecode(cached) as Map<String, dynamic>;
          if (!_disposed && mounted) {
            setState(() {
              _title = '${map['title'] ?? 'Kebijakan Privasi'}';
              _body = '${map['body'] ?? ''}';
              _fromCache = true;
            });
          }
        } catch (_) {}
      }
    } catch (_) {}

    try {
      final item = await _dataSource.getBySlug('privacy');
      if (!mounted || _disposed) return;
      setState(() {
        _title = item.title.isEmpty ? 'Kebijakan Privasi' : item.title;
        _body = item.body.isEmpty ? _fallbackPrivacyBody : item.body;
        _loading = false;
        _fromCache = false;
      });
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _cacheKey,
          jsonEncode({'title': _title, 'body': _body}),
        );
      } catch (_) {}
    } catch (_) {
      if (!mounted || _disposed) return;
      setState(() {
        if (_body.isEmpty) _body = _fallbackPrivacyBody;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _body.isEmpty ? <_Section>[] : _parseSections(_body);
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _loading && _body.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_fromCache)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Menampilkan versi tersimpan (offline)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                if (sections.length > 1)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: const Text('Daftar Isi'),
                      children: [
                        for (var i = 0; i < sections.length; i++)
                          ListTile(
                            dense: true,
                            leading: Text('${i + 1}.'),
                            title: Text(sections[i].heading),
                          ),
                      ],
                    ),
                  ),
                for (var i = 0; i < sections.length; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      initiallyExpanded: i == 0,
                      title: Text(
                        '${i + 1}. ${sections[i].heading}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      children: [
                        if (sections[i].intro.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(sections[i].intro),
                            ),
                          ),
                        for (final sub in sections[i].subs)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.heading,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(sub.body),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
