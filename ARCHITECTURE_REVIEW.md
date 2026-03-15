# Architecture Review: template-python

## 概要

Pythonプロジェクトの開発環境テンプレートリポジトリ。uv・ruff・ty・pytest・pre-commitによる開発基盤を提供し、Python 3.12以上を対象とする。実装コードは存在せず、ツールチェーンの設定が主体。

---

## 理想のアーキテクチャ設計

### 設計方針

Pythonテンプレートリポジトリとして機能するには、「実際のプロジェクトで採用すべき構造のお手本」を示す必要がある。
具体的には以下を満たすべき：

1. **src-layout の完全な実装**: パッケージは `src/{package_name}/` に配置し、インポート問題を防ぐ
2. **CI/CDの提示**: GitHub Actionsを使った自動化の雛形を含める
3. **テスト組織化のパターン提示**: unit/integration の分離とfixtureの使い方を示す
4. **一貫したツールチェーン**: make/pre-commit/pyproject.tomlで同じチェックが走る

### 理想のディレクトリ構造

```text
template-python/
├── .github/
│   └── workflows/
│       ├── ci.yml               # PR/push時にlint・typecheck・testを実行
│       └── release.yml          # tagプッシュ時にPyPI公開
├── src/
│   └── template_python/         # 実際の名前付きパッケージ（src-layout）
│       └── __init__.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py              # 共有フィクスチャ・pytest設定
│   ├── unit/                    # 単体テスト
│   │   └── __init__.py
│   └── integration/             # 結合テスト
│       └── __init__.py
├── .pre-commit-config.yaml      # format・lint・typecheck全て含む
├── pyproject.toml
├── Makefile
├── CHANGELOG.md
└── README.md                    # テンプレートの使い方を含む
```

### モジュール責務詳細

#### `src/template_python/` — アプリケーションコード

**担当すること:**

- 実際のビジネスロジック・機能の配置先
- パッケージのエントリーポイント（`__init__.py`で公開API定義）

**担当しないこと:**

- テストコード・設定ファイル

**他モジュールとの関係:**

- `tests/` から依存される（カバレッジ計測対象）

#### `tests/` — テストコード

**担当すること:**

- `unit/`: 外部依存なしの純粋な関数・クラスのテスト
- `integration/`: 複数モジュールを組み合わせたテスト
- `conftest.py`: pytestフィクスチャの共有定義

**担当しないこと:**

- アプリケーションロジック

#### `.github/workflows/` — CI/CD定義

**担当すること:**

- PR作成時の自動テスト・リント・型チェック
- タグプッシュ時のリリース自動化

### 依存関係の方向

```text
tests/ → src/template_python/
CI (GitHub Actions) → tests/, src/
pre-commit → src/, tests/ （lint/format/typecheck）
pyproject.toml ← Makefile, pre-commit, CI （設定の単一ソース）
```

---

## 現状の問題点

---

### 1. src-layout が不完全 `重大度: 8/10`

**場所:** `src/__init__.py`
**問題:** `src/` 直下に `__init__.py` を置いているため、パッケージ名が `src` になってしまっている。正しい src-layout では `src/{package_name}/__init__.py` とし、`src/` 自体はパッケージにしない。
**影響:** このテンプレートを元にプロジェクトを始めた開発者が `import src` と書くコードを書き、後から名前付きパッケージに移行する際に全ファイルのimportを書き直す羽目になる。カバレッジの `source = ["src/"]` も `src` をパッケージとして計測しており、意図と食い違う可能性がある。
**理想の状態:** `src/template_python/__init__.py` のように名前付きパッケージを配置し、`src/` 自体には `__init__.py` を置かない。`pyproject.toml` の `[tool.ty.src]` や `[tool.coverage.run]` の `source` も対応するパッケージ名に更新する。

---

### 2. GitHub Actions CI/CD が存在しない `重大度: 7/10`

**場所:** リポジトリルート（`.github/workflows/` が存在しない）
**問題:** テンプレートリポジトリにCI/CD設定が含まれていない。
**影響:** このテンプレートを使って新プロジェクトを始めた開発者は、CI設定を一から書く必要がある。「ベストプラクティスの雛形を提供する」というテンプレートの目的に反する。PRマージ時の品質担保が自動化されないため、ローカルで `make lint` / `make test` を手動実行することに依存する。
**理想の状態:** `.github/workflows/ci.yml` を追加し、PushとPRトリガーで `make lint` と `make test` を実行するワークフローを定義する。

---

### 3. テストディレクトリに組織化の雛形がない `重大度: 5/10`

**場所:** `tests/__init__.py`
**問題:** `tests/` に `__init__.py` しか存在しない。`unit/`・`integration/` サブディレクトリも、共有フィクスチャを定義する `conftest.py` も用意されていない。
**影響:** テンプレートを使って開発を始める際に、テストをどう組織化すべきかが示されていない。`conftest.py` がないため、pytestフィクスチャのベストプラクティスも伝わらない。プロジェクトが大きくなるにつれて、全テストがフラットに並ぶ構造になりやすい。
**理想の状態:** `tests/conftest.py`・`tests/unit/__init__.py`・`tests/integration/__init__.py` を最低限追加し、テスト組織化のパターンを示す。

---

### 4. Makefile のヘルプメッセージが古い `重大度: 4/10`

**場所:** `Makefile` の11行目
**問題:** `lint` ターゲットのヘルプに `"Lint code using ruff and mypy"` と書かれているが、実際のコマンドは `ty check`（tyはmypyではない）。
**影響:** 軽微ではあるが、テンプレートを参考にする開発者が「mypyが入っているはず」と誤解し、設定を探し回ることになる。ドキュメントとコードの乖離は認知コストを増やす。
**理想の状態:** `"Lint code using ruff and ty"` に修正する。

---

### 5. README がテンプレートの使い方を説明していない `重大度: 4/10`

**場所:** `README.md`
**問題:** READMEはインストール方法・make コマンドの説明のみで、「このテンプレートを使って新プロジェクトを始める手順」が説明されていない。
**影響:** テンプレートを使おうとする開発者が、パッケージ名の変更箇所（pyproject.toml・src/以下・型チェック設定等）を自分で探す必要がある。
**理想の状態:** 「プロジェクト名・パッケージ名をどこで変更するか」「どのファイルをカスタマイズすべきか」をREADMEに追記する。

---

### 6. `[tool.uv] default-groups = []` で素の `uv sync` が何もインストールしない `重大度: 3/10`

**場所:** `pyproject.toml` の24-25行目
**問題:** `default-groups = []` のため、`uv sync`（引数なし）を実行しても dev・lint・test のいずれの依存関係もインストールされない。`make install` では `--group` フラグを明示しているので問題ないが、ドキュメントに記載がない。
**影響:** READMEを読んで `uv sync` だけ実行した開発者が「何もインストールされない」と困惑する。
**理想の状態:** `default-groups = ["dev", "lint", "test"]` にするか、READMEに「`uv sync` 単体では依存関係がインストールされない。`make install` を使うこと」と明記する。

---

### 7. `D100`（モジュールdocstring）のみを無効化しているが意図が不明瞭 `重大度: 2/10`

**場所:** `pyproject.toml` の61行目 `ignore = ["D100"]`
**問題:** `D` ルール（docstring）を全体で有効にしながら `D100` だけを無効化している。`src/__init__.py` と `tests/__init__.py` にはモジュールdocstringが実際に書かれているため、なぜ無効化しているかの意図が読み取れない。
**影響:** テンプレートを参考にした開発者が、他のdocstringルールとの整合性に困惑する可能性がある。
**理想の状態:** `D100` を無効化する理由をコメントで記載するか、docstringルール全体の採用方針をREADMEに記述する。

---

## 改善の優先順位

1. **最初にやること（重大度7-8）:**
   - `src/` に名前付きパッケージ（例: `src/template_python/`）を作成し、src-layoutを完全な形にする
   - `.github/workflows/ci.yml` を追加し、CI/CDの雛形を提供する

2. **次にやること（重大度5-6）:**
   - `tests/conftest.py`・`tests/unit/`・`tests/integration/` を追加してテスト組織化のパターンを示す

3. **余裕があれば（重大度4以下）:**
   - Makefileのヘルプメッセージを「mypy」→「ty」に修正する
   - READMEにテンプレートの使い方（カスタマイズ箇所）を追記する
   - `default-groups` の挙動をドキュメント化するか設定を変更する

---

## まとめ

このテンプレートはツールチェーンの選定（uv・ruff・ty・pytest）は現代的で適切だが、**「雛形として機能するか」** という観点では不完全な部分が複数ある。最も本質的な問題は、src-layoutが正しく実装されておらず、テンプレートを使い始めた開発者が誤ったパッケージ構造のまま開発を進めるリスクがあることだ。また、make lint と pre-commit の間でチェック内容が一致していない点は、「コミット時は通るがCIで落ちる」という状況を生みやすく、テンプレートが示すべき「一貫した品質担保の仕組み」を体現できていない。CI/CDの雛形がないことも、テンプレートとしての価値を下げている。これら3点を修正するだけで、テンプレートとしての実用性は大きく向上する。
