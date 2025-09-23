function create_shader(gl, shader_type, shader_src) {
    let shader = gl.createShader(shader_type);
    gl.shaderSource(shader, shader_src);
    gl.compileShader(shader);
    let success = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    if (success) {
        return shader;
    }

    console.log(
        "Error while compiling " + shader_type + " shader: " +
        gl.getShaderInfoLog(shader)
    );
    gl.deleteShader(shader);
}

function create_shader_program(gl, v_shader_src, f_shader_src) {

    let v_shader = create_shader(gl, gl.VERTEX_SHADER, v_shader_src);
    let f_shader = create_shader(gl, gl.FRAGMENT_SHADER, f_shader_src);

    let shader_program = gl.createProgram();

    gl.attachShader(shader_program, v_shader);
    gl.attachShader(shader_program, f_shader);

    gl.linkProgram(shader_program);

    let success = gl.getProgramParameter(shader_program, gl.LINK_STATUS);
    if (success) {
        return shader_program;
    }
    
    console.log(
        "Error while compiling shader program: " + 
        gl.getProgramInfoLog(shader_program)
    )
    gl.deleteProgram(shader_program);
}

main();
async function main() {
    const canvas = document.getElementById("canvas");
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    const gl = canvas.getContext("webgl2");
    
    if (!gl) {
        alert("No WebGL.");
        return;
    }

    const get_src = url => fetch(url).then(r => r.text());

    // Swap this out for other shaders
    fragment_source = "/f_shaders/new_shader.glsl"

    const shader = create_shader_program(
        gl, 
        await get_src("/v_shader.glsl"),
        await get_src(fragment_source)
    );

    const pos_att_loc = gl.getAttribLocation(shader, "a_position");
    const resolution_loc = gl.getUniformLocation(shader, "u_resolution");
    const time_loc = gl.getUniformLocation(shader, "u_time");

    const vao = gl.createVertexArray();
    gl.bindVertexArray(vao);

    const posbuff = gl.createBuffer();

    gl.bindBuffer(gl.ARRAY_BUFFER, posbuff);

    gl.bufferData(
        gl.ARRAY_BUFFER,
        new Float32Array([
            -1, -1, 1, -1, -1, 1, 
            -1, 1, 1, -1, 1, 1,
        ]), gl.STATIC_DRAW
    );

    gl.enableVertexAttribArray(pos_att_loc);
    gl.vertexAttribPointer(
        pos_att_loc,
        2, gl.FLOAT, false, 0, 0
    );

    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    gl.useProgram(shader);
    gl.bindVertexArray(vao);

    gl.uniform2f(resolution_loc, gl.canvas.width, gl.canvas.height);
    
    resize_callback();
    window.requestAnimationFrame(render)
    function render(time) {
        time *= 0.001;
        gl.uniform1f(time_loc, time);
        gl.drawArrays(gl.TRIANGLES, 0, 6);
        window.requestAnimationFrame(render);
    }

    function resize_callback() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        gl.canvas.width = canvas.width;
        gl.canvas.height = canvas.height;
        // Update uniforms and viewport
        gl.uniform2f(resolution_loc, gl.canvas.width, gl.canvas.height);
        gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    }
    
    window.onresize = function () {
        resize_callback();
    }
}
    