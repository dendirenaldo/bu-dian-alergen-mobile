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
      if (curSubTitle.isNotEmpty || (hasMdHeading && curTitle.isNotEmpty && curSubs.isNotEmpty)) {
        curSubBuf.add(line);
      } else if (hasMdHeading && curTitle.isNotEmpty && curSubTitle.isNotEmpty) {
        curSubBuf.add(line);
      } else {
        curBuf.add(line);
      }
    }
  }
  flushSec();
  if (hasMdHeading && mdSections.isNotEmpty) return mdSections;

  final text = _stripTags(body).trim();
  if (text.isEmpty) return [];
  return [_Section('Isi', text, [])];
}

const String _fallbackTermsBody = '''
<h2>1. Penerimaan Ketentuan</h2>
<p>Dengan menggunakan aplikasi Allergen Detector, Anda menyetujui ketentuan layanan ini. Jika tidak setuju, mohon tidak menggunakan aplikasi.</p>
<h2>2. Penggunaan Aplikasi</h2>
<p>Aplikasi digunakan untuk membantu mendeteksi alergen pada label makanan melalui OCR dan teks, didukung model Word2Vec-BiLSTM.</p>
<h3>Batasan Hasil</h3>
<p>Hasil deteksi bersifat informatif dan bukan pengganti nasihat medis profesional.</p>
<h2>3. Akun Pengguna</h2>
<p>Anda bertanggung jawab menjaga kerahasiaan kredensial akun dan aktivitas yang terjadi di akun Anda.</p>
<h2>4. Privasi Data</h2>
<p>Pengolahan data tunduk pada Kebijakan Privasi. Gambar yang diunggah dipakai untuk proses deteksi.</p>
<h2>5. Perubahan Layanan</h2>
<p>Kami dapat memperbarui ketentuan ini sewaktu-waktu. Penggunaan berkelanjutan dianggap menyetujui versi terbaru.</p>
''';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  static const _cacheKey = 'contents_terms';
  final _dataSource = ContentsRemoteDataSource();
  bool _loading = true;
  bool _disposed = false;
  String _title = 'Ketentuan Layanan';
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
              _title = '${map['title'] ?? 'Ketentuan Layanan'}';
              _body = '${map['body'] ?? ''}';
              _fromCache = true;
            });
          }
        } catch (_) {}
      }
    } catch (_) {}

    try {
      final item = await _dataSource.getBySlug('terms');
      if (!mounted || _disposed) return;
      setState(() {
        _title = item.title.isEmpty ? 'Ketentuan Layanan' : item.title;
        _body = item.body.isEmpty ? _fallbackTermsBody : item.body;
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
        if (_body.isEmpty) _body = _fallbackTermsBody;
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
