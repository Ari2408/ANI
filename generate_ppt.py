import sys
import os
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
from pptx.dml.color import RGBColor

def create_purb_chetana_ppt():
    prs = Presentation()
    prs.slide_width = Inches(16.0)
    prs.slide_height = Inches(9.0)
    
    # Blank slide layout
    blank_layout = prs.slide_layouts[6]
    slide = prs.slides.add_slide(blank_layout)
    
    # Color Palette (matching exact design specs)
    COLOR_BG = RGBColor(248, 250, 252) # Slate 50
    COLOR_NAVY = RGBColor(15, 23, 42) # Slate 900
    COLOR_BLUE_HEADER = RGBColor(30, 58, 138) # Blue 900
    COLOR_BLUE_CARD = RGBColor(239, 246, 255) # Blue 50
    COLOR_BLUE_BORDER = RGBColor(147, 197, 253) # Blue 300
    COLOR_BLUE_BADGE = RGBColor(37, 99, 235) # Blue 600
    
    COLOR_GREEN_CARD = RGBColor(236, 253, 245) # Emerald 50
    COLOR_GREEN_BORDER = RGBColor(110, 231, 183) # Emerald 300
    COLOR_GREEN_TEXT = RGBColor(4, 120, 87) # Emerald 700
    COLOR_GREEN_BADGE = RGBColor(16, 185, 129)
    
    COLOR_PURPLE_CARD = RGBColor(245, 243, 255) # Purple 50
    COLOR_PURPLE_BORDER = RGBColor(196, 181, 253) # Purple 300
    COLOR_PURPLE_BADGE = RGBColor(124, 58, 237)
    
    COLOR_PINK_CARD = RGBColor(253, 242, 248) # Pink 50
    COLOR_PINK_BORDER = RGBColor(249, 168, 212) # Pink 300
    COLOR_PINK_BADGE = RGBColor(225, 29, 72)
    
    COLOR_ORANGE_CARD = RGBColor(255, 247, 237) # Orange 50
    COLOR_ORANGE_BORDER = RGBColor(253, 186, 116)
    COLOR_ORANGE_BADGE = RGBColor(245, 158, 11)
    
    COLOR_WHITE = RGBColor(255, 255, 255)
    COLOR_DARK_TEXT = RGBColor(30, 41, 59)
    COLOR_MUTED_TEXT = RGBColor(71, 85, 105)

    # 0. Slide Background
    bg_shape = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(16.0), Inches(9.0))
    bg_shape.fill.solid()
    bg_shape.fill.fore_color.rgb = COLOR_BG
    bg_shape.line.fill.background()

    # Helper function for adding rounded card boxes
    def add_card(left, top, width, height, bg_color, border_color, border_width=1.0):
        shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(left), Inches(top), Inches(width), Inches(height))
        shape.fill.solid()
        shape.fill.fore_color.rgb = bg_color
        if border_color:
            shape.line.color.rgb = border_color
            shape.line.width = Pt(border_width)
        else:
            shape.line.fill.background()
        return shape

    # Helper function for adding circle badges
    def add_badge(number, left, top, bg_color, text_color=COLOR_WHITE, size=0.34):
        shape = slide.shapes.add_shape(MSO_SHAPE.OVAL, Inches(left), Inches(top), Inches(size), Inches(size))
        shape.fill.solid()
        shape.fill.fore_color.rgb = bg_color
        shape.line.fill.background()
        tf = shape.text_frame
        tf.word_wrap = False
        tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = Inches(0)
        p = tf.paragraphs[0]
        p.text = str(number)
        p.font.size = Pt(11)
        p.font.bold = True
        p.font.color.rgb = text_color
        p.alignment = PP_ALIGN.CENTER
        return shape

    # ==========================================
    # 1. TOP HEADER SECTION
    # ==========================================
    
    # Left Logo: LUCIFER
    logo_left = add_card(0.25, 0.1, 1.8, 0.75, COLOR_WHITE, RGBColor(203, 213, 225))
    tf_l = logo_left.text_frame
    p_l1 = tf_l.paragraphs[0]
    p_l1.text = "⚔️ LUCIFER"
    p_l1.font.bold = True
    p_l1.font.size = Pt(14)
    p_l1.font.color.rgb = RGBColor(15, 23, 42)
    p_l1.alignment = PP_ALIGN.CENTER

    # Center Main Header
    header_box = slide.shapes.add_textbox(Inches(2.2), Inches(0.02), Inches(11.6), Inches(0.8))
    tf_h = header_box.text_frame
    tf_h.word_wrap = True
    
    p1 = tf_h.paragraphs[0]
    p1.text = "PURB CHETANA"
    p1.font.bold = True
    p1.font.size = Pt(22)
    p1.font.color.rgb = COLOR_BLUE_HEADER
    p1.alignment = PP_ALIGN.CENTER

    p2 = tf_h.add_paragraph()
    p2.text = "Functional Framework & Market Comparison"
    p2.font.bold = True
    p2.font.size = Pt(12)
    p2.font.color.rgb = COLOR_DARK_TEXT
    p2.alignment = PP_ALIGN.CENTER

    p3 = tf_h.add_paragraph()
    p3.text = "Combination of North Eastern Languages (Purb - East, Chetana - Consciousness)"
    p3.font.size = Pt(9.0)
    p3.font.color.rgb = COLOR_MUTED_TEXT
    p3.alignment = PP_ALIGN.CENTER

    # Pill 1: Care Today...
    pill1 = add_card(4.2, 0.82, 4.4, 0.26, RGBColor(204, 251, 241), RGBColor(45, 212, 191))
    p_p1 = pill1.text_frame.paragraphs[0]
    p_p1.text = "Care Today  •  Remember Tomorrow  •  Live Better Together"
    p_p1.font.size = Pt(9.0)
    p_p1.font.bold = True
    p_p1.font.color.rgb = RGBColor(15, 118, 110)
    p_p1.alignment = PP_ALIGN.CENTER

    # Pill 2: Follow numbers...
    pill2 = add_card(8.8, 0.82, 3.0, 0.26, COLOR_WHITE, RGBColor(148, 163, 184))
    p_p2 = pill2.text_frame.paragraphs[0]
    p_p2.text = "Follow the numbers for clear flow"
    p_p2.font.size = Pt(8.5)
    p_p2.font.italic = True
    p_p2.font.color.rgb = COLOR_MUTED_TEXT
    p_p2.alignment = PP_ALIGN.CENTER

    # Right Logo: SIH 2026
    logo_right = add_card(13.95, 0.1, 1.8, 0.75, COLOR_WHITE, RGBColor(203, 213, 225))
    tf_r = logo_right.text_frame
    p_r1 = tf_r.paragraphs[0]
    p_r1.text = "🧠 SMART INDIA"
    p_r1.font.bold = True
    p_r1.font.size = Pt(10)
    p_r1.font.color.rgb = RGBColor(194, 65, 12)
    p_r1.alignment = PP_ALIGN.CENTER
    p_r2 = tf_r.add_paragraph()
    p_r2.text = "HACKATHON 2026"
    p_r2.font.bold = True
    p_r2.font.size = Pt(9)
    p_r2.font.color.rgb = COLOR_NAVY
    p_r2.alignment = PP_ALIGN.CENTER


    # ==========================================
    # 2. TOP STEP WORKFLOW (Steps 1 to 4)
    # ==========================================
    steps_data = [
        (1, "Account Setup &\nLinking (First Step)", ["➕ User profile & initial setup", "🔗 Linking prep"], COLOR_PINK_CARD, COLOR_PINK_BORDER, COLOR_PINK_BADGE, 0.25),
        (2, "Create Elder Account", ["• Register with basic details", "• Set preferences (language, etc.)", "• Unique Elder ID is generated"], COLOR_BLUE_CARD, COLOR_BLUE_BORDER, COLOR_BLUE_BADGE, 4.15),
        (3, "Create Caregiver Account", ["• Register with basic details", "• Enter Elder's Unique ID", "• Verify and request linking"], COLOR_GREEN_CARD, COLOR_GREEN_BORDER, COLOR_GREEN_BADGE, 8.05),
        (4, "Accounts Mapped Successfully", ["• Elder & caregiver accounts linked", "• Both access respective features", "• Stay connected for better care"], COLOR_ORANGE_CARD, COLOR_ORANGE_BORDER, COLOR_ORANGE_BADGE, 11.95)
    ]

    for num, title, bullets, bg_c, brd_c, badge_c, x_pos in steps_data:
        box = add_card(x_pos, 1.15, 3.7, 0.85, bg_c, brd_c)
        add_badge(num, x_pos + 0.08, 1.2, badge_c)
        
        tx = slide.shapes.add_textbox(Inches(x_pos + 0.45), Inches(1.17), Inches(3.2), Inches(0.8))
        tf = tx.text_frame
        tf.word_wrap = True
        tf.margin_top = tf.margin_bottom = Inches(0.01)
        
        p = tf.paragraphs[0]
        p.text = title
        p.font.bold = True
        p.font.size = Pt(9.5)
        p.font.color.rgb = COLOR_NAVY
        
        for b in bullets:
            pb = tf.add_paragraph()
            pb.text = b
            pb.font.size = Pt(7.8)
            pb.font.color.rgb = COLOR_DARK_TEXT

    # Flow arrows between steps
    for arrow_x in [3.97, 7.87, 11.77]:
        arr = slide.shapes.add_shape(MSO_SHAPE.RIGHT_ARROW, Inches(arrow_x), Inches(1.48), Inches(0.16), Inches(0.16))
        arr.fill.solid()
        arr.fill.fore_color.rgb = RGBColor(148, 163, 184)
        arr.line.fill.background()

    # ==========================================
    # 3. LEFT COLUMN: ELDER / SENIOR USER PAGE (X 0.25 to 3.95)
    # ==========================================
    
    # Header Pill
    hdr_elder = add_card(0.25, 2.08, 3.7, 0.3, RGBColor(219, 234, 254), RGBColor(96, 165, 250))
    p_he = hdr_elder.text_frame.paragraphs[0]
    p_he.text = "👤 Elder / Senior User Page"
    p_he.font.bold = True
    p_he.font.size = Pt(10.5)
    p_he.font.color.rgb = RGBColor(29, 78, 216)
    p_he.alignment = PP_ALIGN.CENTER

    # Box 15: Cognitive Exercises
    box15 = add_card(0.25, 2.43, 3.7, 1.25, COLOR_WHITE, COLOR_BLUE_BORDER)
    add_badge(15, 0.32, 2.47, COLOR_BLUE_BADGE)
    
    tx15 = slide.shapes.add_textbox(Inches(0.72), Inches(2.45), Inches(3.18), Inches(1.2))
    tf15 = tx15.text_frame
    tf15.word_wrap = True
    p15 = tf15.paragraphs[0]
    p15.text = "Cognitive Exercises (Complete Today's)"
    p15.font.bold = True
    p15.font.size = Pt(9.2)
    p15.font.color.rgb = COLOR_NAVY
    
    items15 = [
        "🗓️ Routine Sequencer (Arrange daily activities)",
        "🧩 Match Your Memory (Recall & pair items)",
        "🔍 Spot the Difference (Find differences in image)",
        "❓ Cognitive Quiz (Questions about daily life)"
    ]
    for it in items15:
        pi = tf15.add_paragraph()
        pi.text = it
        pi.font.size = Pt(7.2)
        pi.font.color.rgb = COLOR_DARK_TEXT
        
    p15_foot = tf15.add_paragraph()
    p15_foot.text = "Includes personal memories & daily cognitive games."
    p15_foot.font.size = Pt(6.8)
    p15_foot.font.italic = True
    p15_foot.font.color.rgb = COLOR_MUTED_TEXT

    # Box 13: Memory Lane (View)
    box13 = add_card(0.25, 3.73, 1.8, 0.95, COLOR_WHITE, COLOR_BLUE_BORDER)
    add_badge(13, 0.3, 3.77, COLOR_BLUE_BADGE)
    tx13 = slide.shapes.add_textbox(Inches(0.68), Inches(3.75), Inches(1.32), Inches(0.9))
    tf13 = tx13.text_frame
    tf13.word_wrap = True
    p13 = tf13.paragraphs[0]
    p13.text = "Memory Lane (View)"
    p13.font.bold = True
    p13.font.size = Pt(8.8)
    p13.font.color.rgb = COLOR_NAVY
    for it in ["🖼️ View Personal Images", "🎥 Video + Audio Story", "❤️ Relive Memories"]:
        pi = tf13.add_paragraph()
        pi.text = it
        pi.font.size = Pt(7.0)
        pi.font.color.rgb = COLOR_DARK_TEXT

    # Box 16: Digital Wellbeing Features
    box16 = add_card(2.12, 3.73, 1.83, 0.95, COLOR_WHITE, COLOR_BLUE_BORDER)
    add_badge(16, 2.17, 3.77, COLOR_BLUE_BADGE)
    tx16 = slide.shapes.add_textbox(Inches(2.54), Inches(3.75), Inches(1.38), Inches(0.9))
    tf16 = tx16.text_frame
    tf16.word_wrap = True
    p16 = tf16.paragraphs[0]
    p16.text = "Digital Wellbeing"
    p16.font.bold = True
    p16.font.size = Pt(8.8)
    p16.font.color.rgb = COLOR_NAVY
    for it in ["🏃 Step Count Tracking", "🛌 Sleep Duration", "💤 Sleep Health Check"]:
        pi = tf16.add_paragraph()
        pi.text = it
        pi.font.size = Pt(7.0)
        pi.font.color.rgb = COLOR_DARK_TEXT

    # Box 5: Notifications to Elder
    box5 = add_card(0.25, 4.73, 3.7, 0.9, COLOR_GREEN_CARD, COLOR_GREEN_BORDER)
    add_badge(5, 0.32, 4.77, COLOR_GREEN_BADGE)
    tx5 = slide.shapes.add_textbox(Inches(0.72), Inches(4.75), Inches(3.18), Inches(0.85))
    tf5 = tx5.text_frame
    tf5.word_wrap = True
    p5 = tf5.paragraphs[0]
    p5.text = "Notifications to Elder (Senior User)"
    p5.font.bold = True
    p5.font.size = Pt(9.2)
    p5.font.color.rgb = COLOR_NAVY
    for it in ["• Medicine reminders", "• Hydration reminders", "• Daily routine alerts", "• Appointment & Exercise reminders"]:
        pi = tf5.add_paragraph()
        pi.text = it
        pi.font.size = Pt(7.2)
        pi.font.color.rgb = COLOR_DARK_TEXT


    # ==========================================
    # 4. MIDDLE AREA: ML COGNITIVE ANALYSIS & NOTIFICATION FLOW (X 4.08 to 11.75)
    # ==========================================
    
    # Box 19: ML Cognitive Analysis & Dashboard
    box19 = add_card(4.08, 2.08, 3.8, 0.72, COLOR_PURPLE_CARD, COLOR_PURPLE_BORDER)
    add_badge(19, 4.15, 2.12, COLOR_PURPLE_BADGE)
    tx19 = slide.shapes.add_textbox(Inches(4.55), Inches(2.1), Inches(3.28), Inches(0.68))
    tf19 = tx19.text_frame
    tf19.word_wrap = True
    p19 = tf19.paragraphs[0]
    p19.text = "📊 ML Cognitive Analysis & Dashboard"
    p19.font.bold = True
    p19.font.size = Pt(9.2)
    p19.font.color.rgb = RGBColor(91, 33, 182)
    for it in ["• Analyze daily activity, routines, hydration & adherence", "• Cognitive Health Index (Based on User Performance)"]:
        pi = tf19.add_paragraph()
        pi.text = it
        pi.font.size = Pt(7.0)
        pi.font.color.rgb = COLOR_DARK_TEXT

    # Sub-box 20: Past Analysis
    box20 = add_card(4.08, 2.85, 1.85, 0.72, COLOR_WHITE, COLOR_PURPLE_BORDER)
    add_badge(20, 4.13, 2.88, COLOR_PURPLE_BADGE)
    tx20 = slide.shapes.add_textbox(Inches(4.5), Inches(2.87), Inches(1.38), Inches(0.68))
    tf20 = tx20.text_frame
    tf20.word_wrap = True
    p20 = tf20.paragraphs[0]
    p20.text = "Past Analysis"
    p20.font.bold = True
    p20.font.size = Pt(8.2)
    p20.font.color.rgb = RGBColor(91, 33, 182)
    for it in ["• Performance Trends", "• Score History", "• Adherence Analysis"]:
        pi = tf20.add_paragraph()
        pi.text = it
        pi.font.size = Pt(6.6)

    # Sub-box 21: Prediction for Next Week
    box21 = add_card(6.03, 2.85, 1.85, 0.72, COLOR_WHITE, COLOR_PURPLE_BORDER)
    add_badge(21, 6.08, 2.88, COLOR_PURPLE_BADGE)
    tx21 = slide.shapes.add_textbox(Inches(6.45), Inches(2.87), Inches(1.38), Inches(0.68))
    tf21 = tx21.text_frame
    tf21.word_wrap = True
    p21 = tf21.paragraphs[0]
    p21.text = "Prediction Next Week"
    p21.font.bold = True
    p21.font.size = Pt(8.2)
    p21.font.color.rgb = RGBColor(91, 33, 182)
    for it in ["• Expected Trends", "• Risk Alerts (Missed)", "• Caregiver Recs"]:
        pi = tf21.add_paragraph()
        pi.text = it
        pi.font.size = Pt(6.6)

    # Notifications Data Collection & Delivery (Central Teal Hub)
    box_notif_hub = add_card(4.08, 3.62, 3.8, 0.42, RGBColor(204, 251, 241), RGBColor(45, 212, 191))
    tx_nh = slide.shapes.add_textbox(Inches(4.12), Inches(3.64), Inches(3.7), Inches(0.38))
    tf_nh = tx_nh.text_frame
    tf_nh.word_wrap = True
    p_nh1 = tf_nh.paragraphs[0]
    p_nh1.text = "🔔 Notifications (Data Collection & Delivery)"
    p_nh1.font.bold = True
    p_nh1.font.size = Pt(8.8)
    p_nh1.font.color.rgb = RGBColor(15, 118, 110)
    p_nh1.alignment = PP_ALIGN.CENTER
    p_nh2 = tf_nh.add_paragraph()
    p_nh2.text = "Drag-down option to mark 'Taken / Not Taken' | Medicine, routine, hydration"
    p_nh2.font.size = Pt(6.8)
    p_nh2.font.color.rgb = COLOR_DARK_TEXT
    p_nh2.alignment = PP_ALIGN.CENTER

    # Escalation Flow (Steps 8 to 12)
    escalation = [
        (8, "1st Notification", "🔔 Scheduled Time\nTime to take medicine", COLOR_GREEN_CARD, COLOR_GREEN_BORDER, COLOR_GREEN_BADGE, 4.08),
        (9, "2nd Notification", "⚠️ After 3 mins\nReminder: Please take", COLOR_ORANGE_CARD, COLOR_ORANGE_BORDER, COLOR_ORANGE_BADGE, 5.62),
        (10, "3rd Notification", "🚨 After 6 mins\nLast reminder notice", COLOR_PINK_CARD, COLOR_PINK_BORDER, COLOR_PINK_BADGE, 7.16),
        (11, "4th Attempt", "📱 After 9 mins\nSend SOS Alert to Relative", COLOR_PURPLE_CARD, COLOR_PURPLE_BORDER, COLOR_PURPLE_BADGE, 8.7),
        (12, "If App Fail", "✉️ Final Stage\nSend SMS / MMS fallback", RGBColor(254, 226, 226), RGBColor(248, 113, 113), RGBColor(220, 38, 38), 10.24)
    ]

    for num, title, msg, bg_c, brd_c, bdg_c, x_pos in escalation:
        box_esc = add_card(x_pos, 4.10, 1.46, 0.58, bg_c, brd_c)
        add_badge(num, x_pos + 0.05, 4.14, bdg_c, size=0.3)
        
        tx_e = slide.shapes.add_textbox(Inches(x_pos + 0.36), Inches(4.12), Inches(1.06), Inches(0.54))
        tf_e = tx_e.text_frame
        tf_e.word_wrap = True
        tf_e.margin_top = Inches(0.01)
        p_e1 = tf_e.paragraphs[0]
        p_e1.text = title
        p_e1.font.bold = True
        p_e1.font.size = Pt(7.0)
        p_e1.font.color.rgb = COLOR_NAVY
        p_e2 = tf_e.add_paragraph()
        p_e2.text = msg
        p_e2.font.size = Pt(6.2)
        p_e2.font.color.rgb = COLOR_DARK_TEXT

    # Notifications to Caregiver (Box 6)
    box6 = add_card(4.08, 4.73, 3.8, 0.9, COLOR_GREEN_CARD, COLOR_GREEN_BORDER)
    add_badge(6, 4.15, 4.77, COLOR_GREEN_BADGE)
    tx6 = slide.shapes.add_textbox(Inches(4.55), Inches(4.75), Inches(3.28), Inches(0.85))
    tf6 = tx6.text_frame
    tf6.word_wrap = True
    p6 = tf6.paragraphs[0]
    p6.text = "Notifications to Caregiver (Relative)"
    p6.font.bold = True
    p6.font.size = Pt(9.0)
    p6.font.color.rgb = COLOR_NAVY
    for it in ["• Adherence status (Taken / Not Taken)", "• Hydration status & Medicine alerts", "• Routine updates & Emergency alerts"]:
        pi = tf6.add_paragraph()
        pi.text = it
        pi.font.size = Pt(7.0)
        pi.font.color.rgb = COLOR_DARK_TEXT

    # Cognitive Health Index (CHI) Card
    box_chi = add_card(8.0, 4.73, 3.8, 0.9, RGBColor(240, 253, 250), RGBColor(45, 212, 191))
    tx_chi = slide.shapes.add_textbox(Inches(8.05), Inches(4.75), Inches(3.7), Inches(0.85))
    tf_chi = tx_chi.text_frame
    tf_chi.word_wrap = True
    p_c1 = tf_chi.paragraphs[0]
    p_c1.text = "💚 Cognitive Health Index (CHI)"
    p_c1.font.bold = True
    p_c1.font.size = Pt(9.2)
    p_c1.font.color.rgb = RGBColor(15, 118, 110)
    
    p_c2 = tf_chi.add_paragraph()
    p_c2.text = "Medicine (40%) + Routine (30%) + Hydration (20%) + Exercises (10%)"
    p_c2.font.size = Pt(7.0)
    p_c2.font.bold = True
    p_c2.font.color.rgb = COLOR_DARK_TEXT

    p_c3 = tf_chi.add_paragraph()
    p_c3.text = "Higher CHI = Better Cognitive Health | Track progress & identify risks early"
    p_c3.font.size = Pt(6.8)
    p_c3.font.italic = True
    p_c3.font.color.rgb = COLOR_MUTED_TEXT

    # ==========================================
    # 5. RIGHT COLUMN: CAREGIVER PAGE & LANGUAGES (X 11.95 to 15.75)
    # ==========================================

    # Header Pill
    hdr_caregiver = add_card(11.95, 2.08, 3.8, 0.3, RGBColor(209, 250, 229), RGBColor(52, 211, 153))
    p_hc = hdr_caregiver.text_frame.paragraphs[0]
    p_hc.text = "👥 Caregiver / Relative Page"
    p_hc.font.bold = True
    p_hc.font.size = Pt(10.5)
    p_hc.font.color.rgb = RGBColor(4, 120, 87)
    p_hc.alignment = PP_ALIGN.CENTER

    # Box 3: Set & Manage Reminders
    box3 = add_card(11.95, 2.43, 1.85, 1.05, COLOR_WHITE, COLOR_GREEN_BORDER)
    add_badge(3, 12.0, 2.47, COLOR_GREEN_BADGE)
    tx3 = slide.shapes.add_textbox(Inches(12.36), Inches(2.45), Inches(1.4), Inches(1.0))
    tf3 = tx3.text_frame
    tf3.word_wrap = True
    p3 = tf3.paragraphs[0]
    p3.text = "Set & Manage Reminders"
    p3.font.bold = True
    p3.font.size = Pt(8.5)
    p3.font.color.rgb = COLOR_NAVY
    for it in ["• Daily Hydration Limit", "• Medicine Reminders", "• Medical Appointments", "• Daily Routine & Exercises"]:
        pi = tf3.add_paragraph()
        pi.text = it
        pi.font.size = Pt(6.6)

    # Box 9/17: Real-Time Location (GPS Tracking)
    box9_17 = add_card(13.9, 2.43, 1.85, 1.05, COLOR_WHITE, COLOR_GREEN_BORDER)
    add_badge(9, 13.95, 2.47, COLOR_GREEN_BADGE)
    tx9 = slide.shapes.add_textbox(Inches(14.31), Inches(2.45), Inches(1.4), Inches(1.0))
    tf9 = tx9.text_frame
    tf9.word_wrap = True
    p9 = tf9.paragraphs[0]
    p9.text = "Real-Time Location (GPS)"
    p9.font.bold = True
    p9.font.size = Pt(8.5)
    p9.font.color.rgb = COLOR_NAVY
    for it in ["📍 Live elder location", "🗺️ Location history", "🛡️ Geofence safe zones", "🚨 Emergency sharing"]:
        pi = tf9.add_paragraph()
        pi.text = it
        pi.font.size = Pt(6.6)

    # Box 14: Manage Memory Lane (Upload)
    box14 = add_card(11.95, 3.53, 3.8, 0.52, COLOR_WHITE, COLOR_GREEN_BORDER)
    add_badge(14, 12.0, 3.56, COLOR_GREEN_BADGE)
    tx14 = slide.shapes.add_textbox(Inches(12.36), Inches(3.54), Inches(3.35), Inches(0.48))
    tf14 = tx14.text_frame
    tf14.word_wrap = True
    p14 = tf14.paragraphs[0]
    p14.text = "Manage Memory Lane (Upload)"
    p14.font.bold = True
    p14.font.size = Pt(8.5)
    p14.font.color.rgb = COLOR_NAVY
    for it in ["• Upload Personal Important Images", "• Upload Video + Audio Story", "• Organize & Manage Memories"]:
        pi = tf14.add_paragraph()
        pi.text = it
        pi.font.size = Pt(6.6)

    # Box 22: North Eastern Languages Box
    box22 = add_card(11.95, 4.10, 3.8, 0.85, COLOR_GREEN_CARD, COLOR_GREEN_BORDER)
    add_badge(22, 12.0, 4.13, COLOR_GREEN_BADGE)
    tx22 = slide.shapes.add_textbox(Inches(12.38), Inches(4.12), Inches(3.32), Inches(0.81))
    tf22 = tx22.text_frame
    tf22.word_wrap = True
    p22 = tf22.paragraphs[0]
    p22.text = "North Eastern Languages (Voice & Text)"
    p22.font.bold = True
    p22.font.size = Pt(8.2)
    p22.font.color.rgb = COLOR_GREEN_TEXT
    
    langs = [
        "English (en) | गेयाली (ne - Nepali) | অসমীয়া (as - Assamese)",
        "বাংলা (bn - Bengali) | Manipuri (mni) | Mizo (lus - Mizo)",
        "Khasi (kha - Khasi) | हिन्दी (hi - Hindi)"
    ]
    for l in langs:
        pl = tf22.add_paragraph()
        pl.text = l
        pl.font.size = Pt(6.5)
        pl.font.color.rgb = COLOR_DARK_TEXT

    # UI/UX Design Card (Elder Friendly Hex palette table)
    box_ux = add_card(11.95, 5.0, 3.8, 0.63, COLOR_WHITE, RGBColor(203, 213, 225))
    tx_ux = slide.shapes.add_textbox(Inches(12.0), Inches(5.02), Inches(3.7), Inches(0.58))
    tf_ux = tx_ux.text_frame
    tf_ux.word_wrap = True
    p_ux = tf_ux.paragraphs[0]
    p_ux.text = "🎨 UI/UX Design Palette (Elder Friendly)"
    p_ux.font.bold = True
    p_ux.font.size = Pt(8.0)
    p_ux.font.color.rgb = COLOR_NAVY
    
    colors_str = "Primary: #61C580 (Calm) | Text: #182824 (Clear) | Alert: #FF7C57 (Notice) | Emergency: #EF4444 (Attention)"
    p_ux_sub = tf_ux.add_paragraph()
    p_ux_sub.text = colors_str
    p_ux_sub.font.size = Pt(6.2)
    p_ux_sub.font.color.rgb = COLOR_MUTED_TEXT

    # ==========================================
    # 6. BOTTOM SECTION: COMPARISON TABLE & WHY PURB CHETANA (5.7 to 8.8)
    # ==========================================
    
    # Left Side: Comparison Table Header
    table_title = slide.shapes.add_textbox(Inches(0.25), Inches(5.68), Inches(11.4), Inches(0.3))
    tf_tt = table_title.text_frame
    p_tt = tf_tt.paragraphs[0]
    p_tt.text = "Comparison with Existing Applications"
    p_tt.font.bold = True
    p_tt.font.size = Pt(11.5)
    p_tt.font.color.rgb = COLOR_NAVY
    
    rows, cols = 10, 14
    table_shape = slide.shapes.add_table(rows, cols, Inches(0.25), Inches(6.0), Inches(11.5), Inches(2.85))
    table = table_shape.table
    
    table.columns[0].width = Inches(1.5) # App Name
    for c in range(1, 13):
        table.columns[c].width = Inches(0.77) # Attributes
    table.columns[13].width = Inches(0.76) # Total Features
    
    headers = ["Application", "Medicine", "Voice Alerts", "Cognitive Games", "CHI Score", "Memory Lane", "Hydration", "Sleep", "Steps", "GPS", "SOS", "Regional Lang", "Offline", "Total Features"]
    
    for c, h in enumerate(headers):
        cell = table.cell(0, c)
        cell.fill.solid()
        cell.fill.fore_color.rgb = RGBColor(226, 232, 240)
        p = cell.text_frame.paragraphs[0]
        p.text = h
        p.font.bold = True
        p.font.size = Pt(6.8)
        p.font.color.rgb = COLOR_NAVY
        p.alignment = PP_ALIGN.CENTER
        
    app_data = [
        ("Medisafe",    [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 2),
        ("MyTherapy",   [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 1),
        ("Emoha",       [1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0], 3),
        ("Carissa",     [1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0], 4),
        ("MOI",         [1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0], 1),
        ("Healthsoft",  [1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0], 3),
        ("HattaKatta",  [1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0], 3),
        ("Maitri",      [1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], 3),
        ("PurbChetana", [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], 12)
    ]
    
    for r, (app_name, flags, total) in enumerate(app_data, start=1):
        c0 = table.cell(r, 0)
        c0.fill.solid()
        if app_name == "PurbChetana":
            c0.fill.fore_color.rgb = RGBColor(219, 234, 254)
        else:
            c0.fill.fore_color.rgb = COLOR_WHITE
        p0 = c0.text_frame.paragraphs[0]
        p0.text = app_name
        p0.font.bold = (app_name == "PurbChetana")
        p0.font.size = Pt(7.8)
        p0.font.color.rgb = RGBColor(30, 58, 138) if app_name == "PurbChetana" else COLOR_DARK_TEXT
        
        for c, f in enumerate(flags, start=1):
            cell = table.cell(r, c)
            cell.fill.solid()
            p = cell.text_frame.paragraphs[0]
            p.alignment = PP_ALIGN.CENTER
            if f == 1:
                cell.fill.fore_color.rgb = RGBColor(16, 185, 129) # Emerald Green
                p.text = "✓"
                p.font.bold = True
                p.font.size = Pt(8.5)
                p.font.color.rgb = COLOR_WHITE
            else:
                cell.fill.fore_color.rgb = RGBColor(239, 68, 68) # Red
                p.text = "✗"
                p.font.size = Pt(7.5)
                p.font.color.rgb = COLOR_WHITE
                
        ct = table.cell(r, 13)
        ct.fill.solid()
        ct.fill.fore_color.rgb = RGBColor(254, 243, 199) if app_name == "PurbChetana" else RGBColor(241, 245, 249)
        pt = ct.text_frame.paragraphs[0]
        pt.text = str(total)
        pt.alignment = PP_ALIGN.CENTER
        pt.font.bold = True
        pt.font.size = Pt(9.5 if app_name == "PurbChetana" else 8.0)
        pt.font.color.rgb = RGBColor(180, 83, 9) if app_name == "PurbChetana" else COLOR_NAVY

    # Red Highlight Circle on 12 total features for PurbChetana
    oval = slide.shapes.add_shape(MSO_SHAPE.OVAL, Inches(10.98), Inches(8.55), Inches(0.40), Inches(0.28))
    oval.fill.background()
    oval.line.color.rgb = RGBColor(220, 38, 38)
    oval.line.width = Pt(2.5)

    # Right Side: Why PurbChetana Stands Out? Card
    standout_card = add_card(11.95, 5.68, 3.8, 3.17, RGBColor(238, 242, 255), RGBColor(129, 140, 248), border_width=1.5)
    tx_so = slide.shapes.add_textbox(Inches(12.0), Inches(5.72), Inches(3.7), Inches(3.08))
    tf_so = tx_so.text_frame
    tf_so.word_wrap = True
    
    p_so_h = tf_so.paragraphs[0]
    p_so_h.text = "🌟 Why PurbChetana Stands Out?"
    p_so_h.font.bold = True
    p_so_h.font.size = Pt(10.5)
    p_so_h.font.color.rgb = RGBColor(30, 58, 138)
    p_so_h.alignment = PP_ALIGN.CENTER
    
    points = [
        "🧠 Complete cognitive care ecosystem",
        "🗣️ Supports North Eastern languages",
        "📱 Works offline with SMS fallback",
        "📍 Real-time GPS tracking & geofencing",
        "🤖 AI-powered insights & predictions",
        "❤️ Designed for elders, families & caregivers"
    ]
    for pt in points:
        p_pt = tf_so.add_paragraph()
        p_pt.text = pt
        p_pt.font.size = Pt(8.0)
        p_pt.font.color.rgb = COLOR_DARK_TEXT
        
    p_so_foot = tf_so.add_paragraph()
    p_so_foot.text = "More Care  |  More Connection  |  A Healthier Tomorrow"
    p_so_foot.font.size = Pt(7.8)
    p_so_foot.font.bold = True
    p_so_foot.font.color.rgb = RGBColor(79, 70, 229)
    p_so_foot.alignment = PP_ALIGN.CENTER

    # Save presentation
    output_path = "/home/dinakar3108/Downloads/PR1/PurbChetana_Framework_Presentation.pptx"
    prs.save(output_path)
    print(f"Successfully generated PowerPoint presentation at: {output_path}")

if __name__ == "__main__":
    create_purb_chetana_ppt()
