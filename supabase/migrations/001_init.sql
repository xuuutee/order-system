-- ============================================
-- 订单管理系统 — 数据库初始化 (MVP Phase 1)
-- ============================================

-- 0. Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. 团队成员
CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 订单类型
CREATE TABLE order_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  icon TEXT DEFAULT 'assignment',
  fields_schema JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 订单主表
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_no TEXT NOT NULL UNIQUE,
  type_id UUID REFERENCES order_types(id),
  customer_name TEXT NOT NULL,
  customer_contact TEXT,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT '待接单' CHECK (status IN ('待接单','进行中','已交付','已收款','已关闭','取消')),
  primary_owner UUID REFERENCES team_members(id),
  deadline TIMESTAMPTZ,
  price DECIMAL(10,2),
  cost DECIMAL(10,2),
  extra JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES team_members(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 协作关系
CREATE TABLE order_assignees (
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  member_id UUID REFERENCES team_members(id),
  task_note TEXT,
  PRIMARY KEY (order_id, member_id)
);

-- 5. 状态变更历史
CREATE TABLE order_status_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_by UUID REFERENCES team_members(id),
  changed_at TIMESTAMPTZ DEFAULT NOW(),
  note TEXT
);

-- 6. 附件
CREATE TABLE order_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  uploaded_by UUID REFERENCES team_members(id),
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. 收支记录
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('收入','支出')),
  paid_at TIMESTAMPTZ DEFAULT NOW(),
  note TEXT,
  recorded_by UUID REFERENCES team_members(id)
);

-- ============================================
-- 订单编号生成 (并发安全)
-- ============================================
CREATE SEQUENCE order_no_seq;

CREATE OR REPLACE FUNCTION generate_order_no()
RETURNS TRIGGER AS $$
BEGIN
  NEW.order_no := 'OD' || to_char(NOW(), 'YYYYMMDD') || LPAD(nextval('order_no_seq')::text, 3, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_no
  BEFORE INSERT ON orders
  FOR EACH ROW
  WHEN (NEW.order_no IS NULL)
  EXECUTE FUNCTION generate_order_no();

-- ============================================
-- RLS 策略
-- ============================================

-- 判断当前用户是否在团队成员表中
CREATE OR REPLACE FUNCTION is_team_member()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM team_members WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "team_read_orders" ON orders FOR SELECT USING (is_team_member());
CREATE POLICY "team_insert_orders" ON orders FOR INSERT WITH CHECK (is_team_member());
CREATE POLICY "team_update_orders" ON orders FOR UPDATE USING (is_team_member());
CREATE POLICY "team_delete_orders" ON orders FOR DELETE USING (is_team_member());

-- order_types
ALTER TABLE order_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "team_read_order_types" ON order_types FOR SELECT USING (is_team_member());
CREATE POLICY "team_insert_order_types" ON order_types FOR INSERT WITH CHECK (is_team_member());
CREATE POLICY "team_update_order_types" ON order_types FOR UPDATE USING (is_team_member());
CREATE POLICY "team_delete_order_types" ON order_types FOR DELETE USING (is_team_member());

-- team_members
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "team_read_team_members" ON team_members FOR SELECT USING (is_team_member());
CREATE POLICY "team_insert_team_members" ON team_members FOR INSERT WITH CHECK (is_team_member());
CREATE POLICY "team_update_team_members" ON team_members FOR UPDATE USING (is_team_member());

-- order_assignees
ALTER TABLE order_assignees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "team_read_order_assignees" ON order_assignees FOR SELECT USING (is_team_member());
CREATE POLICY "team_insert_order_assignees" ON order_assignees FOR INSERT WITH CHECK (is_team_member());
CREATE POLICY "team_update_order_assignees" ON order_assignees FOR UPDATE USING (is_team_member());
CREATE POLICY "team_delete_order_assignees" ON order_assignees FOR DELETE USING (is_team_member());

-- order_status_logs
ALTER TABLE order_status_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "team_read_order_status_logs" ON order_status_logs FOR SELECT USING (is_team_member());
CREATE POLICY "team_insert_order_status_logs" ON order_status_logs FOR INSERT WITH CHECK (is_team_member());

-- order_attachments
ALTER TABLE order_attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "team_read_order_attachments" ON order_attachments FOR SELECT USING (is_team_member());
CREATE POLICY "team_insert_order_attachments" ON order_attachments FOR INSERT WITH CHECK (is_team_member());
CREATE POLICY "team_update_order_attachments" ON order_attachments FOR UPDATE USING (is_team_member());
CREATE POLICY "team_delete_order_attachments" ON order_attachments FOR DELETE USING (is_team_member());

-- payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "team_read_payments" ON payments FOR SELECT USING (is_team_member());
CREATE POLICY "team_insert_payments" ON payments FOR INSERT WITH CHECK (is_team_member());
CREATE POLICY "team_update_payments" ON payments FOR UPDATE USING (is_team_member());
CREATE POLICY "team_delete_payments" ON payments FOR DELETE USING (is_team_member());

-- ============================================
-- 初始数据
-- ============================================
INSERT INTO order_types (name, icon, fields_schema) VALUES
('网课代修', 'school', '[
  {"key":"course_platform","label":"课程平台","type":"text","required":true},
  {"key":"course_name","label":"课程名称","type":"text","required":true},
  {"key":"course_url","label":"课程链接","type":"url","required":false},
  {"key":"progress","label":"当前进度(%)","type":"number","required":false}
]'),
('PPT制作', 'slideshow', '[
  {"key":"page_count","label":"页数","type":"number","required":true},
  {"key":"topic","label":"主题","type":"text","required":true},
  {"key":"template","label":"模板要求","type":"text","required":false},
  {"key":"language","label":"语言","type":"select","options":["中文","英文"],"required":false}
]'),
('文档排版', 'description', '[
  {"key":"page_count","label":"页数","type":"number","required":true},
  {"key":"doc_type","label":"文档类型","type":"select","options":["论文","报告","简历","其他"],"required":true},
  {"key":"format","label":"目标格式","type":"select","options":["Word","LaTeX","PDF"],"required":true},
  {"key":"reference_count","label":"参考文献数","type":"number","required":false}
]');
