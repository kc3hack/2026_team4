-- Pikumei Supabase スキーマ
-- Supabase Dashboard > SQL Editor で実行してください

-- ============================================================
-- 1. monsters テーブル
-- ============================================================
CREATE TABLE monsters (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL REFERENCES auth.users(id),
    classification_label  TEXT NOT NULL,
    thumbnail             BYTEA NOT NULL,  -- JPEG 200x200 ~10KB
    created_at            TIMESTAMPTZ DEFAULT now()
);

-- RLS を有効化
ALTER TABLE monsters ENABLE ROW LEVEL SECURITY;

-- 自分のモンスターは CRUD 可能
CREATE POLICY "Users can manage own monsters"
    ON monsters FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 他人のモンスターは閲覧のみ
CREATE POLICY "Anyone can view monsters"
    ON monsters FOR SELECT
    USING (true);

-- ============================================================
-- 2. battles テーブル
-- ============================================================
CREATE TABLE battles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status              TEXT NOT NULL DEFAULT 'waiting',
                        -- 'waiting' → 'matched' → 'finished'
    player1_id          UUID NOT NULL REFERENCES auth.users(id),
    player1_monster_id  UUID NOT NULL REFERENCES monsters(id),
    player2_id          UUID REFERENCES auth.users(id),
    player2_monster_id  UUID REFERENCES monsters(id),
    winner_id           UUID REFERENCES auth.users(id),
    created_at          TIMESTAMPTZ DEFAULT now()
);

-- RLS を有効化
ALTER TABLE battles ENABLE ROW LEVEL SECURITY;

-- バトルは誰でも閲覧可能
CREATE POLICY "Anyone can view battles"
    ON battles FOR SELECT
    USING (true);

-- waiting 状態のバトルは誰でも作成可能
CREATE POLICY "Users can create battles"
    ON battles FOR INSERT
    WITH CHECK (auth.uid() = player1_id);

-- 参加者のみ更新可能（player2 の JOIN / winner の記録）
CREATE POLICY "Participants can update battles"
    ON battles FOR UPDATE
    USING (auth.uid() = player1_id OR auth.uid() = player2_id);

-- ============================================================
-- 3. Realtime を有効化
-- ============================================================
-- Supabase Dashboard > Database > Replication で
-- battles テーブルの Realtime を有効にしてください
-- （SQL ではなく GUI で設定）

-- ============================================================
-- 4. Anonymous Auth を有効化
-- ============================================================
-- Supabase Dashboard > Authentication > Providers で
-- Anonymous Sign-Ins を有効にしてください
