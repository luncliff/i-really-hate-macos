#pragma once
#include <memory>
#include <string>
#include <system_error>
#include <type_traits>

#if defined(__APPLE__)
#define GL_SILENCE_DEPRECATION
#include <OpenGL/OpenGL.h> // _OPENGL_H
// #include <OpenGL/gl.h>     // __gl_h_
// #include <OpenGL/glext.h>  // __glext_h_
#define GL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED
#include <OpenGL/gl3.h>    // __gl3_h_
#include <OpenGL/gl3ext.h> // __gl3ext_h_
#endif

static_assert(__cplusplus >= 201402L, "requires C++14 or later");

/** @brief `std::error_category` for OpenGL errors */
std::error_category& get_opengl_category() noexcept;

/**
 * @brief OpenGL Vertex Array Object + RAII
 */
struct opengl_vao_t final {
    GLuint name;

  public:
    opengl_vao_t() noexcept(false);
    ~opengl_vao_t() noexcept(false);

    opengl_vao_t(const opengl_vao_t&) = delete;
    opengl_vao_t& operator=(const opengl_vao_t&) = delete;
    opengl_vao_t(opengl_vao_t&&) = delete;
    opengl_vao_t& operator=(opengl_vao_t&&) = delete;

    GLenum bind() const noexcept;
};

/**
 * @brief OpenGL Shader Program + RAII
 */
struct opengl_program_t final {
    const GLuint id, vs, fs;

  public:
    opengl_program_t(std::string vtxt, //
                     std::string ftxt) noexcept(false);
    ~opengl_program_t() noexcept;
    opengl_program_t(const opengl_program_t&) = delete;
    opengl_program_t& operator=(const opengl_program_t&) = delete;
    opengl_program_t(opengl_program_t&&) = delete;
    opengl_program_t& operator=(opengl_program_t&&) = delete;

    operator bool() const noexcept;

    GLenum use() const noexcept;
    GLint uniform(const char* name) const noexcept;
    GLint attribute(const char* name) const noexcept;

  private:
    static GLuint create_compile_attach(GLuint program, GLenum shader_type, //
                                        std::string code) noexcept(false);
    static bool
    get_shader_info(std::string& message, //
                    GLuint shader,
                    GLenum status_name = GL_COMPILE_STATUS) noexcept;
    static bool get_program_info(std::string& message, //
                                 GLuint program,
                                 GLenum status_name = GL_LINK_STATUS) noexcept;
};

/**
 * @brief OpenGL Texture + RAII
 */
struct opengl_texture_t final {
    GLuint name;
    GLenum target;

  public:
    opengl_texture_t(GLuint name, GLenum target) noexcept(false);
    opengl_texture_t(uint32_t width, uint32_t height, //
                     void* ptr) noexcept(false);
    ~opengl_texture_t() noexcept(false);

    opengl_texture_t(const opengl_texture_t&) = delete;
    opengl_texture_t& operator=(const opengl_texture_t&) = delete;
    opengl_texture_t(opengl_texture_t&&);
    opengl_texture_t& operator=(opengl_texture_t&&);

    operator bool() const noexcept;
    GLenum bind() const noexcept;
    GLenum update(uint32_t width, uint32_t height, void* ptr) noexcept;
};

/**
 * @brief OpenGL FrameBuffer + RAII
 * @code
 * glBindFramebuffer(GL_FRAMEBUFFER, fbo.name);
 * @endcode
 */
struct opengl_framebuffer_t {
    GLuint name;
    GLuint buffers[2]{}; // color, depth
  public:
    opengl_framebuffer_t(uint32_t width, uint32_t height) noexcept(false);
    ~opengl_framebuffer_t() noexcept;

    opengl_framebuffer_t(const opengl_framebuffer_t&) = delete;
    opengl_framebuffer_t& operator=(const opengl_framebuffer_t&) = delete;
    opengl_framebuffer_t(opengl_framebuffer_t&&) = delete;
    opengl_framebuffer_t& operator=(opengl_framebuffer_t&&) = delete;

    GLenum bind() const noexcept;
    GLenum read_rgba(const GLint rectangle[4], uint8_t* buffer);
};

/**
 * @brief OpenGL Texture Renderer with intenal binding management
 */
class texture_renderer_t {
  public:
    virtual ~texture_renderer_t() noexcept = default;

    /**
     * @brief Render the Texture with the given GL Context
     *
     * @param context GL Context for the internal binding
     * @param texture Name of the OpenGL Texture
     * @param target  Type of the OpenGL Texture
     * @return GLenum Return value of the `glGetError`
     */
    virtual GLenum render(void* context, //
                          GLuint texture,
                          GLenum target = GL_TEXTURE_2D) noexcept = 0;
};

auto make_tex2d_renderer() noexcept(false)
    -> std::unique_ptr<texture_renderer_t>;
