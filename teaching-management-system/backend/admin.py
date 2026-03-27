from flask import Blueprint, render_template, session, request, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

def get_db():
    conn = psycopg2.connect(
        host='127.0.0.1',
        port=8888,
        user='postgres',
        password='postgres',
        database='teaching_system'
    )
    return conn

# 管理员首页（保留原来的权限校验）
@admin_bp.route('/')
def index():
    if session.get('role') != 'admin':
        return redirect('/')
    return render_template('admin.html', user=session)

# -------------------------- 课程管理接口 --------------------------
# 获取所有课程 / 搜索课程
@admin_bp.route('/courses', methods=['GET'])
def get_courses():
    search = request.args.get('name', '')
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    if search:
        cur.execute("SELECT * FROM courses WHERE course_name ILIKE %s", (f'%{search}%',))
    else:
        cur.execute("SELECT * FROM courses")
    courses = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(courses)

# 获取单个课程
@admin_bp.route('/courses/<int:id>', methods=['GET'])
def get_course(id):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM courses WHERE id = %s", (id,))
    course = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(course)

# 新增课程
@admin_bp.route('/courses', methods=['POST'])
def add_course():
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO courses (course_code, course_name, english_name, credit, total_hours, teacher_id, semester, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, (data['courseCode'], data['courseName'], data.get('englishName', ''), data['credit'], data['totalHours'], data.get('teacherId', ''), data['semester'], data['status']))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"msg": "success"})

# 更新课程
@admin_bp.route('/courses/<int:id>', methods=['PUT'])
def update_course(id):
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        UPDATE courses SET course_code=%s, course_name=%s, english_name=%s, credit=%s, total_hours=%s, teacher_id=%s, semester=%s, status=%s
        WHERE id=%s
    """, (data['courseCode'], data['courseName'], data.get('englishName', ''), data['credit'], data['totalHours'], data.get('teacherId', ''), data['semester'], data['status'], id))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"msg": "success"})

# 删除课程
@admin_bp.route('/courses/<int:id>', methods=['DELETE'])
def delete_course(id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("DELETE FROM courses WHERE id=%s", (id,))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"msg": "success"})

# -------------------------- 学生管理接口 --------------------------
@admin_bp.route('/students', methods=['GET'])
def get_students():
    search = request.args.get('name', '')
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    if search:
        cur.execute("SELECT * FROM students WHERE name ILIKE %s", (f'%{search}%',))
    else:
        cur.execute("SELECT * FROM students")
    students = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(students)

@admin_bp.route('/students/<student_id>', methods=['GET'])
def get_student(student_id):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM students WHERE student_id = %s", (student_id,))
    student = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(student)

@admin_bp.route('/students', methods=['POST'])
def add_student():
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO students (student_id, name, gender, major, class_name, grade, phone, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, (data['studentId'], data['name'], data['gender'], data['major'], data.get('className', ''), data['grade'], data.get('phone', ''), data['status']))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"msg": "success"})

@admin_bp.route('/students/<student_id>', methods=['PUT'])
def update_student(student_id):
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        UPDATE students SET name=%s, gender=%s, major=%s, class_name=%s, grade=%s, phone=%s, status=%s
        WHERE student_id=%s
    """, (data['name'], data['gender'], data['major'], data.get('className', ''), data['grade'], data.get('phone', ''), data['status'], student_id))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"msg": "success"})

@admin_bp.route('/students/<student_id>', methods=['DELETE'])
def delete_student(student_id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("DELETE FROM students WHERE student_id=%s", (student_id,))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"msg": "success"})

# -------------------------- 教师管理接口 --------------------------
@admin_bp.route('/teachers', methods=['GET'])
def get_teachers():
    search = request.args.get('name', '')
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    if search:
        cur.execute("SELECT * FROM teachers WHERE name ILIKE %s", (f'%{search}%',))
    else:
        cur.execute("SELECT * FROM teachers")
    teachers = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(teachers)

@admin_bp.route('/teachers/<teacher_id>', methods=['GET'])
def get_teacher(teacher_id):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM teachers WHERE teacher_id = %s", (teacher_id,))
    teacher = cur.fetchone()
    cur.close()
    conn.close()
    return jsonify(teacher)

@admin_bp.route('/teachers', methods=['POST'])
def add_teacher():
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO teachers (teacher_id, name, gender, title, department, phone, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (data['teacherId'], data['name'], data['gender'], data.get('title', ''), data['department'], data.get('phone', ''), data['status']))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"msg": "success"})

@admin_bp.route('/teachers/<teacher_id>', methods=['PUT'])
def update_teacher(teacher_id):
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        UPDATE teachers SET name=%s, gender=%s, title=%s, department=%s, phone=%s, status=%s
        WHERE teacher_id=%s
    """, (data['name'], data['gender'], data.get('title', ''), data['department'], data.get('phone', ''), data['status'], teacher_id))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"msg": "success"})

@admin_bp.route('/teachers/<teacher_id>', methods=['DELETE'])
def delete_teacher(teacher_id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("DELETE FROM teachers WHERE teacher_id=%s", (teacher_id,))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"msg": "success"})
