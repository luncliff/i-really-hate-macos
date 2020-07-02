#include "opengl_es.h"

using namespace std;

opengl_vao_t::opengl_vao_t() noexcept(false) {
    glGenVertexArrays(1, &name);
    if (int ec = glGetError())
        throw system_error{ec, get_opengl_category(), "glGenVertexArrays"};
}
opengl_vao_t::~opengl_vao_t() noexcept(false) {
    glDeleteVertexArrays(1, &name);
    if (int ec = glGetError())
        throw system_error{ec, get_opengl_category(), "glDeleteVertexArrays"};
}

GLenum opengl_vao_t::bind() const noexcept {
    glBindVertexArray(name);
    return glGetError();
}

bool opengl_program_t::get_shader_info(string& message, GLuint shader,
                                       GLenum status_name) noexcept {
    GLint info = GL_FALSE;
    glGetShaderiv(shader, status_name, &info);
    if (info != GL_TRUE) {
        GLsizei buf_len = 400;
        message.resize(buf_len);
        glGetShaderInfoLog(shader, buf_len, &buf_len, (char*)message.data());
        message.resize(buf_len); // shrink
    }
    return info;
}

bool opengl_program_t::get_program_info(string& message, GLuint program,
                                        GLenum status_name) noexcept {
    GLint info = GL_TRUE;
    glGetProgramiv(program, status_name, &info);
    if (info != GL_TRUE) {
        GLsizei buf_len = 400;
        message.resize(buf_len);
        glGetProgramInfoLog(program, buf_len, &buf_len, (char*)message.data());
        message.resize(buf_len); // shrink
    }
    return info;
}

GLuint opengl_program_t::create_compile_attach(GLuint program,
                                               GLenum shader_type,
                                               string code) noexcept(false) {
    auto shader = glCreateShader(shader_type);
    const GLchar* begin = code.data();
    const GLint len = code.length();
    glShaderSource(shader, 1, &begin, &len);
    glCompileShader(shader);
    string message{};
    if (get_shader_info(message, shader, GL_COMPILE_STATUS) == false)
        throw runtime_error{message};

    glAttachShader(program, shader);
    return shader;
}

opengl_program_t::opengl_program_t(string vtxt, //
                                   string ftxt) noexcept(false)
    : id{glCreateProgram()}, vs{create_compile_attach(id, GL_VERTEX_SHADER,
                                                      move(vtxt))},
      fs{create_compile_attach(id, GL_FRAGMENT_SHADER, move(ftxt))} {
    glLinkProgram(id);
    string message{};
    if (get_program_info(message, id, GL_LINK_STATUS) == false)
        throw runtime_error{message};
}

opengl_program_t::~opengl_program_t() noexcept {
    glDeleteShader(vs);
    glDeleteShader(fs);
    glDeleteProgram(id);
}

opengl_program_t::operator bool() const noexcept {
    return glIsProgram(id);
}

GLenum opengl_program_t::use() const noexcept {
    glUseProgram(id);
    return glGetError();
}

GLint opengl_program_t::uniform(const char* name) const noexcept {
    return glGetUniformLocation(id, name);
}
GLint opengl_program_t::attribute(const char* name) const noexcept {
    return glGetAttribLocation(id, name);
}

opengl_texture_t::operator bool() const noexcept {
    return glIsTexture(this->name);
}

opengl_texture_t::opengl_texture_t(GLuint _name, GLenum _target) noexcept(false)
    : name{_name}, target{_target} {
    if (glIsTexture(this->name) == false)
        throw invalid_argument{"not texture"};
}

opengl_texture_t::opengl_texture_t(uint32_t width, uint32_t height,
                                   void* ptr) noexcept(false)
    : name{} // with the signature
      ,
      target{GL_TEXTURE_2D} // we can sure the type is GL_TEXTURE_2D

{
    glGenTextures(1, &name);
    if (int ec = glGetError())
        throw system_error{ec, get_opengl_category(), "glGenTextures"};

    glBindTexture(target, name);
    glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    if (int ec = update(width, height, ptr))
        throw system_error{ec, get_opengl_category(), "glTexImage2D"};
    glBindTexture(target, 0);
}

opengl_texture_t::~opengl_texture_t() noexcept(false) {
    if (name == 0)
        return;

    glDeleteTextures(1, &name);
    if (int ec = glGetError())
        throw system_error{ec, get_opengl_category(), "glDeleteTextures"};
}
GLenum opengl_texture_t::update(uint32_t width, uint32_t height,
                                void* ptr) noexcept {
    glBindTexture(target, name);
    constexpr auto level = 0, border = 0;
    glTexImage2D(target, level,                  // no mipmap
                 GL_RGBA, width, height, border, //
                 GL_RGBA, GL_UNSIGNED_BYTE, ptr);
    return glGetError();
}

opengl_texture_t& opengl_texture_t::operator=(opengl_texture_t&& rhs) {
    swap(this->name, rhs.name);
    swap(this->target, rhs.target);
    return *this;
}
opengl_texture_t::opengl_texture_t(opengl_texture_t&& rhs)
    : name{rhs.name}, target{rhs.target} {
    rhs.name = 0;
}

GLenum opengl_texture_t::bind() const noexcept {
    glBindTexture(target, name);
    return glGetError();
}

opengl_framebuffer_t::opengl_framebuffer_t(uint32_t width,
                                           uint32_t height) noexcept(false) {
    if (width * height == 0)
        throw invalid_argument{"width * height == 0"};
    glGenFramebuffers(1, &name);
    glBindFramebuffer(GL_FRAMEBUFFER, name);
    glGenRenderbuffers(2, buffers);
    {
        glBindRenderbuffer(GL_RENDERBUFFER, buffers[0]);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
        if (int ec = glGetError())
            throw system_error{
                ec, get_opengl_category(),
                "glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, ...)"};
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                  GL_RENDERBUFFER, buffers[0]);
    }
    {
        glBindRenderbuffer(GL_RENDERBUFFER, buffers[1]);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width,
                              height);
        if (int ec = glGetError())
            throw system_error{ec, get_opengl_category(),
                               "glRenderbufferStorage(GL_RENDERBUFFER, "
                               "GL_DEPTH_COMPONENT16, ...)"};
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                  GL_RENDERBUFFER, buffers[1]);
    }
    switch (glCheckFramebufferStatus(GL_FRAMEBUFFER)) {
#if defined(_WIN32) // OpenGL ES
    case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
        throw runtime_error{"GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS"};
#endif
    case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
        throw runtime_error{"GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT"};
    case GL_FRAMEBUFFER_UNSUPPORTED:
        throw runtime_error{"GL_FRAMEBUFFER_UNSUPPORTED"};
    case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
        throw runtime_error{"GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT"};
    case GL_FRAMEBUFFER_COMPLETE:
    default:
        break;
    }
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}
opengl_framebuffer_t::~opengl_framebuffer_t() noexcept {
    glDeleteRenderbuffers(2, buffers);
    glDeleteFramebuffers(1, &name);
}

GLenum opengl_framebuffer_t::bind() const noexcept {
    glBindFramebuffer(GL_FRAMEBUFFER, name);
    return glGetError();
}

GLenum opengl_framebuffer_t::read_rgba(const GLint rectangle[4],
                                       uint8_t* buffer) {
    glBindFramebuffer(GL_FRAMEBUFFER, name);
    // glReadBuffer(GL_COLOR_ATTACHMENT0);
    glReadPixels(rectangle[0], rectangle[1], rectangle[2], rectangle[3], //
                 GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    return glGetError();
}

class opengl_dictionary_t : public error_category {
    const char* name() const noexcept override {
#if defined(_WIN32)
        return "OpenGL ES";
#elif defined(__APPLE__)
        return "OpenGL";
#endif
    }

    string message(int ec = glGetError()) const override {
        char buf[40]{};
#if defined(_WIN32)
        auto len = sprintf_s(buf, "%d(%x)", ec, ec);
        return {buf, static_cast<size_t>(len)};
#else
        auto len = sprintf(buf, "%d(%x)", ec, ec);
        return {buf, static_cast<size_t>(len)};
#endif
    }
};

opengl_dictionary_t ecategory{};

error_category& get_opengl_category() noexcept {
    return ecategory;
};

// for OpenGL ES 3.0 ...
GLenum get_opengl_texture_size(GLuint texture, GLenum target, //
                               GLint& width, GLint& height) {
    glBindTexture(target, texture);
    const GLint mipmap = 0;
    glGetTexLevelParameteriv(target, mipmap, GL_TEXTURE_WIDTH, &width);
    glGetTexLevelParameteriv(target, mipmap, GL_TEXTURE_HEIGHT, &height);
    glBindTexture(target, 0);
    return glGetError();
}

/**
 * @brief GL_TEXTURE_2D renderer with OpenGL ES 2.0
 * @see ANGLE project
 */
struct tex2d_renderer_t final : public texture_renderer_t {
    const opengl_program_t program;
    opengl_vao_t vao{};
    GLuint vbo, ebo;
    GLint u_mvp, a_position, a_texcoord, a_color;

  public:
    /**
     * @throw runtime_error
     */
    explicit tex2d_renderer_t();
    virtual ~tex2d_renderer_t() noexcept;

  private:
    GLenum unbind(void* context);
    GLenum bind(void* context);
    GLenum render(void* context, //
                  GLuint texture, GLenum target) noexcept override;
};

auto make_tex2d_renderer() noexcept(false) -> unique_ptr<texture_renderer_t> {
    return make_unique<tex2d_renderer_t>();
}

tex2d_renderer_t::~tex2d_renderer_t() noexcept {
    glDeleteBuffers(1, &vbo);
    glDeleteBuffers(1, &ebo);
}

tex2d_renderer_t::tex2d_renderer_t()
    : program{R"(
#version 150
uniform mat4 u_mvp;
in vec4 a_position;
in vec2 a_texcoord;
in vec3 a_color;
out vec3 v_color;
out vec2 v_texcoord;

void main()
{
    gl_Position = u_mvp * a_position;
    v_color = a_color;
    v_texcoord = a_texcoord;
}
)",
              R"(
#version 150
precision mediump float;

uniform sampler2D u_tex2d;
in vec3 v_color;
in vec2 v_texcoord;
out vec4 o_color;

void main()
{
    vec3 color = texture(u_tex2d, v_texcoord).rgb;
    o_color = vec4(color, 1);
}
)"},
      vao{} {
    if (auto ec = vao.bind())
        throw runtime_error{"glBindVertexArray"};

    constexpr float ratio = 0.970f, z0 = 0; // render (almost) full-size
    constexpr float tx0 = 0, ty0 = 0, tx = 1, ty = 1;
    const GLfloat vertices[] = {
        // position, color, texture coord
        ratio,  ratio,  z0, 1, 1, 1, tx,  ty,  // top right
        ratio,  -ratio, z0, 1, 1, 1, tx,  ty0, // bottom right
        -ratio, -ratio, z0, 1, 1, 1, tx0, ty0, // bottom left
        -ratio, ratio,  z0, 1, 1, 1, tx0, ty   // top left
    };
    glGenBuffers(1, &vbo);
    if (int ec = glGetError())
        throw system_error{ec, get_opengl_category(), "glGenBuffers"};

    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, //
                 GL_STATIC_DRAW);
    if (int ec = glGetError())
        throw system_error{ec, get_opengl_category(), "glBufferData"};
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    const GLuint indices[] = {
        0, 1, 3, // triangle 1
        1, 2, 3  // triangle 2
    };
    glGenBuffers(1, &ebo);
    if (int ec = glGetError())
        throw system_error{ec, get_opengl_category(), "glGenBuffers"};

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, //
                 GL_STATIC_DRAW);
    if (int ec = glGetError())
        throw system_error{ec, get_opengl_category(), "glBufferData"};
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    u_mvp = a_position = a_texcoord = a_color = -1;
}

GLenum tex2d_renderer_t::unbind(void*) {
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    return glGetError();
}

GLenum tex2d_renderer_t::bind(void*) {
    glUseProgram(program.id);
    if (auto ec = glGetError())
        return ec;

    glBindVertexArray(vao.name);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    if (auto ec = glGetError())
        return ec;
    if (u_mvp == -1) {
        constexpr auto name = "u_mvp";
        u_mvp = program.uniform(name);
        if (u_mvp < 0)
            throw runtime_error{name};
        const float mvp[]{
            1, 0, 0, 0, //
            0, 1, 0, 0, //
            0, 0, 1, 0, //
            0, 0, 0, 1  //
        };
        glUniformMatrix4fv(u_mvp, 1, GL_FALSE, mvp);
        if (int ec = glGetError())
            throw system_error{ec, get_opengl_category(), "glUniformMatrix4fv"};
    }
    if (a_position == -1) {
        constexpr auto name = "a_position";
        a_position = program.attribute(name);
        if (a_position < 0)
            throw runtime_error{name};
        glVertexAttribPointer(a_position, 3, GL_FLOAT, //
                              GL_FALSE, 8 * sizeof(float), (void*)0);
        if (int ec = glGetError())
            throw system_error{ec, get_opengl_category(),
                               "glVertexAttribPointer"};
        glEnableVertexAttribArray(a_position);
    }
    if (a_color == -1) {
        constexpr auto name = "a_color";
        a_color = program.attribute(name);
        if (a_color < 0)
            throw runtime_error{name};
        glVertexAttribPointer(a_color, 3, GL_FLOAT, //
                              GL_FALSE, 8 * sizeof(float),
                              (void*)(3 * sizeof(float)));
        if (int ec = glGetError())
            throw system_error{ec, get_opengl_category(),
                               "glVertexAttribPointer"};
        glEnableVertexAttribArray(a_color);
    }
    if (a_texcoord == -1) {
        constexpr auto name = "a_texcoord";
        a_texcoord = program.attribute(name);
        if (a_texcoord < 0)
            throw runtime_error{name};
        glVertexAttribPointer(a_texcoord, 2, GL_FLOAT, //
                              GL_FALSE, 8 * sizeof(float),
                              (void*)(6 * sizeof(float)));
        if (int ec = glGetError())
            throw system_error{ec, get_opengl_category(),
                               "glVertexAttribPointer"};
        glEnableVertexAttribArray(a_texcoord);
    }
    return glGetError();
}

GLenum tex2d_renderer_t::render(void* context, //
                                GLuint texture, GLenum target) noexcept {
    if (auto ec = this->bind(context))
        return ec;
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(target, texture);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    if (auto ec = glGetError())
        return ec;
    glBindTexture(target, 0);
    return this->unbind(context);
}
