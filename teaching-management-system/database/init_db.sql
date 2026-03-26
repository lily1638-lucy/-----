-- ==================== 创建数据库 ====================
CREATE DATABASE teaching_system;
\c teaching_system;

-- ==================== 删除旧表 ====================
DROP TABLE IF EXISTS announcement_reads CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS operation_logs CASCADE;
DROP TABLE IF EXISTS score_history CASCADE;
DROP TABLE IF EXISTS course_reviews CASCADE;
DROP TABLE IF EXISTS course_resources CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS course_categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS teachers CASCADE;
DROP TABLE IF EXISTS admins CASCADE;

-- ==================== 1. 学生基本信息表（预先存在） ====================
CREATE TABLE students (
    student_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
    major VARCHAR(100),
    class_name VARCHAR(50),
    grade INTEGER,
    id_card VARCHAR(18),
    phone VARCHAR(20),
    email VARCHAR(100),
    enrollment_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'graduated')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 2. 教师基本信息表（预先存在） ====================
CREATE TABLE teachers (
    teacher_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
    title VARCHAR(50),
    department VARCHAR(100),
    id_card VARCHAR(18),
    phone VARCHAR(20),
    email VARCHAR(100),
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'retired')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 3. 管理员基本信息表（预先存在） ====================
CREATE TABLE admins (
    admin_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    role VARCHAR(50),
    department VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 4. 系统用户表（注册后才有） ====================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    real_name VARCHAR(50) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'teacher', 'admin')),
    -- 关联真实身份
    student_id VARCHAR(20) REFERENCES students(student_id),
    teacher_id VARCHAR(20) REFERENCES teachers(teacher_id),
    admin_id VARCHAR(20) REFERENCES admins(admin_id),
    
    email VARCHAR(100),
    phone VARCHAR(20),
    last_login TIMESTAMP,
    status INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- 确保角色对应的ID不为空
    CHECK (
        (role = 'student' AND student_id IS NOT NULL) OR
        (role = 'teacher' AND teacher_id IS NOT NULL) OR
        (role = 'admin' AND admin_id IS NOT NULL)
    )
);

-- ==================== 5. 课程类别表 ====================
CREATE TABLE course_categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    parent_id INTEGER REFERENCES course_categories(id),
    description TEXT
);

-- ==================== 6. 课程表 ====================
CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    course_code VARCHAR(20) UNIQUE NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    english_name VARCHAR(200),
    category_id INTEGER REFERENCES course_categories(id),
    credit DECIMAL(3,1) NOT NULL,
    total_hours INTEGER,
    theory_hours INTEGER,
    lab_hours INTEGER,
    teacher_id VARCHAR(20) REFERENCES teachers(teacher_id),
    capacity INTEGER DEFAULT 50,
    enrolled INTEGER DEFAULT 0,
    semester VARCHAR(20) NOT NULL,
    schedule VARCHAR(500),
    location VARCHAR(200),
    prerequisites TEXT,
    syllabus TEXT,
    textbook VARCHAR(200),
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'closed', 'full')),
    is_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 7. 选课表 ====================
CREATE TABLE enrollments (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL REFERENCES students(student_id),
    course_id INTEGER NOT NULL REFERENCES courses(id),
    score DECIMAL(5,2),
    grade_point DECIMAL(3,2),
    status VARCHAR(20) DEFAULT 'selected' CHECK (status IN ('selected', 'dropped', 'completed', 'failed')),
    midterm_score DECIMAL(5,2),
    final_score DECIMAL(5,2),
    homework_score DECIMAL(5,2),
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, course_id)
);

-- ==================== 8. 成绩修改历史表 ====================
CREATE TABLE score_history (
    id SERIAL PRIMARY KEY,
    enrollment_id INTEGER REFERENCES enrollments(id) ON DELETE CASCADE,
    old_score DECIMAL(5,2),
    new_score DECIMAL(5,2),
    reason VARCHAR(200),
    modified_by INTEGER REFERENCES users(id),
    modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 9. 公告表 ====================
CREATE TABLE announcements (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    target_role VARCHAR(20) CHECK (target_role IN ('all', 'student', 'teacher', 'admin')),
    publish_by INTEGER REFERENCES users(id),
    publish_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expire_at TIMESTAMP,
    is_published BOOLEAN DEFAULT TRUE
);

-- ==================== 10. 操作日志表 ====================
CREATE TABLE operation_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100),
    target_type VARCHAR(50),
    target_id VARCHAR(50),
    details JSONB,
    ip_address VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 创建索引 ====================
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_student_id ON users(student_id);
CREATE INDEX idx_users_teacher_id ON users(teacher_id);
CREATE INDEX idx_courses_teacher_id ON courses(teacher_id);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);

-- ==================== 自动更新时间触发器 ====================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_enrollments_updated_at BEFORE UPDATE ON enrollments
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ==================== 计算绩点函数 ====================
CREATE OR REPLACE FUNCTION calculate_grade_point(score DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
    IF score >= 90 THEN RETURN 4.0;
    ELSIF score >= 85 THEN RETURN 3.7;
    ELSIF score >= 82 THEN RETURN 3.3;
    ELSIF score >= 78 THEN RETURN 3.0;
    ELSIF score >= 75 THEN RETURN 2.7;
    ELSIF score >= 72 THEN RETURN 2.3;
    ELSIF score >= 68 THEN RETURN 2.0;
    ELSIF score >= 64 THEN RETURN 1.5;
    ELSIF score >= 60 THEN RETURN 1.0;
    ELSE RETURN 0.0;
    END IF;
END;
$$ language 'plpgsql';

-- 自动计算绩点触发器
CREATE OR REPLACE FUNCTION auto_calc_gpa()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.score IS NOT NULL THEN
        NEW.grade_point = calculate_grade_point(NEW.score);
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER enrollments_calc_gpa BEFORE INSERT OR UPDATE ON enrollments
FOR EACH ROW EXECUTE FUNCTION auto_calc_gpa();

-- ==================== 插入测试数据（预先存在的学生、教师、管理员） ====================

-- 插入学生基本信息（这些是学校已有的学生，需要先存在）
INSERT INTO students (student_id, name, gender, major, class_name, grade, phone, email, enrollment_date) VALUES
('20240001', '王小明', 'male', '计算机科学与技术', '计科1班', 2024, '13812340001', 'wangxiaoming@school.edu', '2024-09-01'),
('20240002', '李小红', 'female', '计算机科学与技术', '计科1班', 2024, '13812340002', 'lixiaohong@school.edu', '2024-09-01'),
('20240003', '张大力', 'male', '软件工程', '软工1班', 2024, '13812340003', 'zhangdali@school.edu', '2024-09-01'),
('20240004', '赵婷婷', 'female', '软件工程', '软工1班', 2024, '13812340004', 'zhaotingting@school.edu', '2024-09-01'),
('20230001', '陈思远', 'male', '计算机科学与技术', '计科2班', 2023, '13812340005', 'chensiyuan@school.edu', '2023-09-01'),
('20230002', '刘雨桐', 'female', '数据科学与大数据技术', '大数据1班', 2023, '13812340006', 'liuyutong@school.edu', '2023-09-01'),
('20220001', '周子涵', 'male', '计算机科学与技术', '计科1班', 2022, '13812340007', 'zhouzihan@school.edu', '2022-09-01'),
('20220002', '吴雨霏', 'female', '软件工程', '软工2班', 2022, '13812340008', 'wuyufei@school.edu', '2022-09-01');

-- 插入教师基本信息（学校已有的教师）
INSERT INTO teachers (teacher_id, name, gender, title, department, phone, email, hire_date) VALUES
('T2024001', '张建国', 'male', '教授', '计算机科学与技术学院', '13812340101', 'zhangjg@school.edu', '2010-09-01'),
('T2024002', '李芳', 'female', '副教授', '计算机科学与技术学院', '13812340102', 'lifang@school.edu', '2015-09-01'),
('T2024003', '王明', 'male', '讲师', '软件学院', '13812340103', 'wangming@school.edu', '2018-09-01'),
('T2024004', '陈丽华', 'female', '教授', '数学学院', '13812340104', 'chenlihua@school.edu', '2008-09-01'),
('T2024005', '赵志远', 'male', '副教授', '外国语学院', '13812340105', 'zhaozhiyuan@school.edu', '2012-09-01');

-- 插入管理员基本信息（学校已有的管理员）
INSERT INTO admins (admin_id, name, role, department, phone, email) VALUES
('A001', '系统管理员', '超级管理员', '网络中心', '13812349999', 'admin@school.edu'),
('A002', '教务处王老师', '教务管理员', '教务处', '13812349998', 'jwchu@school.edu'),
('A003', '学工处李老师', '学生管理员', '学生工作处', '13812349997', 'xuegong@school.edu');

-- ==================== 插入课程类别 ====================
INSERT INTO course_categories (category_name, description) VALUES
('计算机类', '计算机相关课程'),
('数学类', '数学基础课程'),
('通识类', '通识教育课程'),
('外语类', '外语课程'),
('工程类', '工程实践课程');

-- ==================== 插入课程 ====================
INSERT INTO courses (course_code, course_name, english_name, category_id, credit, total_hours, teacher_id, capacity, semester, schedule, location, is_required) VALUES
('CS101', '数据库系统原理', 'Database System Principles', 1, 3.5, 64, 'T2024001', 60, '2024-2025-1', '周一 1-2节, 周三 3-4节', '计算机楼A101', TRUE),
('CS102', '操作系统', 'Operating Systems', 1, 3.5, 64, 'T2024001', 55, '2024-2025-1', '周二 1-2节, 周四 3-4节', '计算机楼A102', TRUE),
('CS103', 'Python程序设计', 'Python Programming', 1, 3.0, 48, 'T2024002', 50, '2024-2025-1', '周一 5-6节, 周三 5-6节', '计算机楼A201', FALSE),
('CS104', '数据结构', 'Data Structures', 1, 4.0, 72, 'T2024002', 60, '2024-2025-1', '周三 1-2节, 周五 3-4节', '计算机楼A103', TRUE),
('MA101', '高等数学A', 'Advanced Mathematics A', 2, 5.0, 80, 'T2024004', 100, '2024-2025-1', '周一 3-4节, 周三 1-2节, 周五 1-2节', '教学楼A101', TRUE),
('MA102', '线性代数', 'Linear Algebra', 2, 3.0, 48, 'T2024004', 80, '2024-2025-1', '周二 3-4节, 周四 5-6节', '教学楼A102', TRUE),
('EN101', '大学英语', 'College English', 4, 4.0, 64, 'T2024005', 80, '2024-2025-1', '周二 1-2节, 周四 1-2节', '教学楼B101', TRUE),
('SE201', '软件工程', 'Software Engineering', 5, 3.0, 48, 'T2024003', 45, '2024-2025-1', '周五 1-2节, 周五 3-4节', '软件楼B101', TRUE);

-- ==================== 插入选课记录 ====================
INSERT INTO enrollments (student_id, course_id) VALUES
('20240001', 1), ('20240001', 2), ('20240001', 4), ('20240001', 5), ('20240001', 7),
('20240002', 1), ('20240002', 3), ('20240002', 5), ('20240002', 6), ('20240002', 7),
('20240003', 3), ('20240003', 4), ('20240003', 5), ('20240003', 8),
('20240004', 3), ('20240004', 5), ('20240004', 6), ('20240004', 7), ('20240004', 8),
('20230001', 1), ('20230001', 2), ('20230001', 4), ('20230001', 5),
('20230002', 3), ('20230002', 5), ('20230002', 6);

-- 更新课程已选人数
UPDATE courses SET enrolled = (
    SELECT COUNT(*) FROM enrollments WHERE course_id = courses.id
);

-- ==================== 插入已注册的用户（已经有账号的） ====================
INSERT INTO users (username, password, real_name, role, student_id, teacher_id, admin_id, email, phone) VALUES
('admin', 'e10adc3949ba59abbe56e057f20f883e', '系统管理员', 'admin', NULL, NULL, 'A001', 'admin@school.edu', '13812349999'),
('wangxiaoming', 'e10adc3949ba59abbe56e057f20f883e', '王小明', 'student', '20240001', NULL, NULL, 'wangxiaoming@school.edu', '13812340001'),
('lixiaohong', 'e10adc3949ba59abbe56e057f20f883e', '李小红', 'student', '20240002', NULL, NULL, 'lixiaohong@school.edu', '13812340002'),
('zhangdali', 'e10adc3949ba59abbe56e057f20f883e', '张大力', 'student', '20240003', NULL, NULL, 'zhangdali@school.edu', '13812340003'),
('zhangjg', 'e10adc3949ba59abbe56e057f20f883e', '张建国', 'teacher', NULL, 'T2024001', NULL, 'zhangjg@school.edu', '13812340101'),
('lifang', 'e10adc3949ba59abbe56e057f20f883e', '李芳', 'teacher', NULL, 'T2024002', NULL, 'lifang@school.edu', '13812340102'),
('wangming', 'e10adc3949ba59abbe56e057f20f883e', '王明', 'teacher', NULL, 'T2024003', NULL, 'wangming@school.edu', '13812340103');

-- ==================== 插入公告 ====================
INSERT INTO announcements (title, content, target_role, publish_by) VALUES
('新学期选课通知', '本学期选课将于9月1日开始，请同学们及时选课。选课系统开放时间为每天8:00-22:00。', 'student', 1),
('教师成绩录入通知', '请各位老师在考试结束后一周内完成成绩录入。成绩录入系统已开放。', 'teacher', 1),
('系统维护通知', '本周六凌晨2:00-4:00系统维护，请合理安排使用时间。', 'all', 1),
('新生入学教育', '2024级新生入学教育将于9月5日在报告厅举行，请全体新生参加。', 'student', 2);