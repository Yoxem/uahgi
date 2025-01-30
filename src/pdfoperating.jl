module PDFOperating
using libharu_jll
using FreeType

"""
using TeX-like metrics, in px
 - height
 - weight
 - depth
"""
struct CharMetrics
    ht::Float64
    dp::Float64  
    wd::Float64  
end

#the default path is Noto Serif CJK Regular
#default_font_path = "src/thirdParty/fonts/noto/NotoSerifTC-Regular.ttf"
default_font_path = "src/thirdParty/fonts/linuxLibertine/LinLibertine_Rah.ttf"

function createPDF()
    #=returns pdf=#
    pdf = @ccall libhpdf.HPDF_New(""::Cstring, 0::Cint)::Ptr{Cvoid}
    #using utf-8
    @ccall libhpdf.HPDF_UseUTFEncodings(pdf::Ptr{Cvoid})::Ptr{Cvoid}; 
    @ccall libhpdf.HPDF_SetCurrentEncoder(pdf::Ptr{Cvoid}, "UTF-8"::Cstring)::Ptr{float}; 
    return pdf
end

function addPage(pdf)
    page = @ccall libhpdf.HPDF_AddPage(pdf::Ptr{Cvoid})::Ptr{Cvoid}
    return page
end

function load_font(pdf, font_path,index=0)
    HPDF_TRUE = 1
    # only available in ttf and ttc
    is_ttf = match(r".+\.ttf$", font_path)
    is_ttc = match(r".+\.ttc$", font_path)
    if is_ttf !== nothing
        font_name = @ccall libhpdf.HPDF_LoadTTFontFromFile(
            pdf::Ptr{Cvoid},
            font_path::Cstring, HPDF_TRUE::Cint)::Cstring
    elseif is_ttc !== nothing
            font_name = @ccall libhpdf.HPDF_LoadTTFontFromFile2(
            pdf::Ptr{Cvoid},
            font_path::Cstring,
            index::Cuint,
            HPDF_TRUE::Cint)::Cstring
            
    else
        throw("the format of \"$font_path\" is not valid!")
    end
    font = @ccall libhpdf.HPDF_GetFont(
        pdf::Ptr{Cvoid},
        font_name::Cstring,
        "UTF-8"::Cstring)::Ptr{Cvoid};
    
    return font
end

function put_text(page, text, font, size, x, y)
    # set font and size
    @ccall libhpdf.HPDF_Page_SetFontAndSize(
        page::Ptr{Cvoid},
        font::Ptr{Cvoid},
        float(size)::Cfloat)::Ptr{Cvoid};
    
    #declare putting text
    @ccall libhpdf.HPDF_Page_BeginText(
        page::Ptr{Cvoid})::Ptr{Cvoid}
    
    # put the text on
    @ccall libhpdf.HPDF_Page_TextOut(
        page::Ptr{Cvoid},
        float(x)::Cfloat,
        float(y)::Cfloat,
        text::Cstring)::Ptr{Cvoid};
    
    # end of putting text
    @ccall libhpdf.HPDF_Page_EndText(
        page::Ptr{Cvoid})::Ptr{Cvoid}
    
end

function save_pdf(pdf, file_name)
    @ccall libhpdf.HPDF_SaveToFile(
        pdf::Ptr{Cvoid},
        file_name::Cstring)::Ptr{Cvoid};
end

function check_char_size(char, font_path, font_size, font_index=0)
    library = Vector{FT_Library}(undef, 1)
    error = FT_Init_FreeType(library)
    face = Ref{FT_Face}()
    FT_New_Face(library[1], string(font_path), 0, face)
    glyph_index = FT_Get_Char_Index(face[], char)
    FT_Load_Glyph(face[], glyph_index, FT_LOAD_NO_SCALE)
    faceRec = unsafe_load(face[])
    glyphrec = unsafe_load(faceRec.glyph)

    metrics = glyphrec.metrics
    # horizonal mode
    width = metricToPx(metrics.horiAdvance, font_size) * 0.75
    #from baseline up to top of the glyph
    height = metricToPx(metrics.horiBearingY, font_size) * 0.75
    #from baseline down to the bottom of the glyph
    depth = metricToPx(metrics.height - metrics.horiBearingY, font_size) * 0.75


    return CharMetrics(height, depth, width)
end

"""
convert freetype metric unit to px with fontsize in pt
"""
function metricToPx(metric, size_pt)
    return metric * size_pt / 750
end

#pdf = createPDF()
#page = addPage(pdf)
#font = load_font(pdf, default_font_path)
#put_text(page, "上下abc", font, 15, 100, 200)
#put_text(page, "天地人", font, 15, 200, 200)

#save_pdf(pdf, "text.pdf")

#println("PDF generated.")
#check_char_size(
#    '安',
#    default_font_path,
#    20)
"""generate_pdf"""
function generate_pdf(box_list, file_path)
    pdf = createPDF()
    page = addPage(pdf)
    for ch in box_list
        font = load_font(pdf, ch.font_path)
        put_text(page, ch.char, font, ch.size, ch.x, ch.y)
    end
    save_pdf(pdf, file_path)
end

end
