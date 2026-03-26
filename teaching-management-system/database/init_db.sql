-- ==================== 创建数据库 ====================
CREATE DATABASE teaching_system;
\c teaching_system;

-- ==================== 1. 用户表 ====================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    real_name VARCHAR(50) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'teacher', 'admin')),
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
    birthday DATE,
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    avatar_url VARCHAR(500),
    last_login TIMESTAMP,
    status INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 2. 学生表 ====================
CREATE TABLE students (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    student_id VARCHAR(20) UNIQUE NOT NULL,
    major VARCHAR(100),
    class_name VARCHAR(50),
    grade INTEGER,
    advisor_id INTEGER,
    enrollment_date DATE,
    graduation_date DATE,
    credits_earned DECIMAL(10,2) DEFAULT 0,
    gpa DECIMAL(3,2) DEFAULT 0
);

-- ==================== 3. 教师表 ====================
CREATE TABLE teachers (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    teacher_id VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(50),
    department VARCHAR(100),
    office VARCHAR(50),
    office_phone VARCHAR(20),
    research_area TEXT,
    hire_date DATE
);

-- 添加辅导员外键
ALTER TABLE students ADD FOREIGN KEY (advisor_id) REFERENCES teachers(user_id);

-- ==================== 4. 课程类别表 ====================
CREATE TABLE course_categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    parent_id INTEGER REFERENCES course_categories(id),
    description TEXT
);

-- ==================== 5. 课程表 ====================
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
    teacher_id INTEGER REFERENCES teachers(user_id),
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

-- ==================== 6. 选课表 ====================
CREATE TABLE enrollments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES students(user_id),
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

-- ==================== 7. 成绩修改历史表 ====================
CREATE TABLE score_history (
    id SERIAL PRIMARY KEY,
    enrollment_id INTEGER REFERENCES enrollments(id) ON DELETE CASCADE,
    old_score DECIMAL(5,2),
    new_score DECIMAL(5,2),
    reason VARCHAR(200),
    modified_by INTEGER REFERENCES users(id),
    modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 8. 课程资源表 ====================
CREATE TABLE course_resources (
    id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE,
    resource_type VARCHAR(20) CHECK (resource_type IN ('syllabus', 'material', 'homework', 'exam', 'video')),
    title VARCHAR(200),
    file_url VARCHAR(500),
    description TEXT,
    upload_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 9. 课程评价表 ====================
CREATE TABLE course_reviews (
    id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE,
    student_id INTEGER REFERENCES students(user_id),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(course_id, student_id)
);

-- ==================== 10. 公告表 ====================
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

-- ==================== 11. 公告阅读记录 ====================
CREATE TABLE announcement_reads (
    id SERIAL PRIMARY KEY,
    announcement_id INTEGER REFERENCES announcements(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(announcement_id, user_id)
);

-- ==================== 12. 操作日志表 ====================
CREATE TABLE operation_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100),
    target_type VARCHAR(50),
    target_id INTEGER,
    details JSONB,
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 创建索引 ====================
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_students_student_id ON students(student_id);
CREATE INDEX idx_teachers_teacher_id ON teachers(teacher_id);
CREATE INDEX idx_courses_teacher_id ON courses(teacher_id);
CREATE INDEX idx_courses_semester ON courses(semester);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);

-- ==================== 自动更新时间的触发器 ====================
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

-- ==================== 自动计算绩点的函数 ====================
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

-- 插入成绩时自动计算绩点的触发器
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

-- ==================== 插入测试数据 ====================
-- 插入用户（密码都是 123456）
INSERT INTO users (username, password, real_name, role, gender, email, phone) VALUES
('admin', 'e10adc3949ba59abbe56e057f20f883e', '系统管理员', 'admin', 'male', 'admin@school.edu', '13800000000'),
('teacher_zhang', 'e10adc3949ba59abbe56e057f20f883e', '张建国', 'teacher', 'male', 'zhangjg@school.edu', '13812340001'),
('teacher_li', 'e10adc3949ba59abbe56e057f20f883e', '李芳', 'teacher', 'female', 'lifang@school.edu', '13812340002'),
('student_wang', 'e10adc3949ba59abbe56e057f20f883e', '王小明', 'student', 'male', 'wangxm@school.edu', '13812340010'),
('student_li', 'e10adc3949ba59abbe56e057f20f883e', '李小红', 'student', 'female', 'lixh@school.edu', '13812340011'),
('student_zhao', 'e10adc3949ba59abbe56e057f20f883e', '赵大力', 'student', 'male', 'zhaodl@school.edu', '13812340012');

-- 插入教师扩展信息
INSERT INTO teachers (user_id, teacher_id, title, department, office, research_area, hire_date) VALUES
(2, 'T2024001', '教授', '计算机科学与技术学院', '计算机楼A301', '数据库系统、大数据', '2010-09-01'),
(3, 'T2024002', '副教授', '计算机科学与技术学院', '计算机楼A302', '操作系统、分布式系统', '2015-09-01');

-- 插入学生扩展信息
INSERT INTO students (user_id, student_id, major, class_name, grade, advisor_id, enrollment_date, graduation_date) VALUES
(4, '2024001', '计算机科学与技术', '计科1班', 2024, 2, '2024-09-01', '2028-06-30'),
(5, '2024002', '计算机科学与技术', '计科1班', 2024, 2, '2024-09-01', '2028-06-30'),
(6, '2024003', '软件工程', '软工1班', 2024, 3, '2024-09-01', '2028-06-30');

-- 插入课程类别
INSERT INTO course_categories (category_name, description) VALUES
('计算机类', '计算机相关课程'),
('数学类', '数学基础课程'),
('通识类', '通识教育课程');

-- 插入课程
INSERT INTO courses (course_code, course_name, credit, teacher_id, capacity, semester, schedule, location, is_required) VALUES
('CS101', '数据库系统原理', 3.5, 2, 60, '2024-2025-1', '周一 1-2节, 周三 3-4节', '计算机楼A101', TRUE),
('CS102', '操作系统', 3.5, 2, 55, '2024-2025-1', '周二 1-2节, 周四 3-4节', '计算机楼A102', TRUE),
('CS103', 'Python程序设计', 3.0, 3, 50, '2024-2025-1', '周一 5-6节, 周三 5-6节', '计算机楼A201', FALSE),
('MA101', '高等数学A', 5.0, NULL, 100, '2024-2025-1', '周一 3-4节, 周三 1-2节, 周五 1-2节', '教学楼A101', TRUE);

-- 插入选课记录
INSERT INTO enrollments (student_id, course_id) VALUES
(4, 1), (4, 2), (4, 4),
(5, 1), (5, 3),
(6, 3), (6, 4);

-- 更新课程已选人数
UPDATE courses SET enrolled = (
    SELECT COUNT(*) FROM enrollments WHERE course_id = courses.id
);

-- 插入公告
INSERT INTO announcements (title, content, target_role, publish_by) VALUES
('新学期选课通知', '本学期选课将于9月1日开始，请同学们及时选课。', 'student', 1),
('教师成绩录入通知', '请各位老师在考试结束后一周内完成成绩录入。', 'teacher', 1);