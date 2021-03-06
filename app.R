# package, data and local script loading -------------------------------------------

library(shiny)
library(shinydashboard)
library(DESeq2)
library(stringr)
library(tidyr)
library(ggplot2)
library(plotly)
library(shinythemes)
library(clusterProfiler)
library(pathview)

options(stringsAsFactors = FALSE)
source("scripts/gene_dot_plot.R")
source("scripts/volcano_plot.R")

symbol <- read.table("data/ath_gene_alias.txt",
                     sep="\t",
                     header = TRUE)
colnames(symbol) <- c("geneID", "SYMBOL")

# dashboard sidebar -------------------------------------------------------

dashboardsider <- dashboardSidebar(
  sidebarMenu(
    menuItem("Data Upload", tabName = "DataUpload", icon = icon("file-upload")),
    menuItem("Diagnosis", tabName = "Diagnosis", icon = icon("stethoscope")),
    menuItem("DEG Analysis", tabName = "DEG", icon = icon("not-equal")),
    menuItem("DEG Exploration", tabName = "Exp", icon = icon("search")),
    menuItem("Enrichment Analysis", tabName = "Enrichment", icon = icon("list")),
    menuItem("GSEA", tabName = "GSEA", icon = icon("sort-amount-down"))
  )
  
)


# Body content ------------------------------------------------------------

dashboardbody <- dashboardBody(
  
  tabItems(

# tabItem: data load ------------------------------------------------------
    tabItem(tabName = "DataUpload",
            
            # Loading RNA-seq
            fluidRow(
              shinydashboard::box(
              title = "UpLoad expression matrix", status = "primary",
              solidHeader = TRUE,
              
              fileInput("upload_mat", 
                        label = "Upload expression matrix file",
                        accept = c("text/plain",
                                   ".txt"))
              
            ),
            
            # Add Group information
            # box2 start
            shinydashboard::box(
              
              title = "Select control and case", status = "warning",
              solidHeader = TRUE,
              
              selectizeInput("input_control",
                             label = "Select the control group",
                             choices = NULL,
                             multiple = TRUE,
                             options = list(
                               placeholder = "Select the control group",
                               maxOptions = 20
                             )),
              
              selectizeInput("input_case",
                             label = "Select the case group",
                             choices = NULL,
                             multiple = TRUE,
                             options = list(
                               placeholder = "Select the case group",
                               maxOptions = 20
                             )),
              
              actionButton("submit2", label = "Run")
            ) # box2 end
    ), # box1 end
    fluidRow(
      shinydashboard::box(
               DT::dataTableOutput("dataset2"),
               title = "All raw read count",
               width = 12
      )
      
    )
),
# tabItem: Diagnosis ------------------------------------------------------
    tabItem( tabName = "Diagnosis",

             shinydashboard::box(
                        fluidRow(plotOutput("pcaplot")),
                        #fluidRow(
                        #  tags$p("For batch plotting, only the first gene will be displayed above. Please download the file for all plots. "),
                        #  downloadLink("download_ratioplot","SNP Ratio plot download"))
                      
                      title = "PCA Plot", 
                      width = 12
                      
             )
    ),

# tabItem: DEG Analysis ---------------------------------------------------
    tabItem( tabName = "DEG",
             tags$p("First Run log2 fold change threshold ONCE, and then Run Filter by logFoldChange
", style="font-size: 20px"),
             tags$p("DO NOT Run log2 fold change threshold too many times",
                    style="font-size: 20px; color: red"),
             fluidRow(
               shinydashboard::box(
                      
                      sliderInput("input_LFC",
                                  label = "log2 fold change threshold",
                                  min = -4,
                                  max =  4,
                                  value = 0,
                                  step = 0.1
                      ),
                      
                      selectInput("input_methods",
                                  label = "Select p value adjust methods",
                                  choices = p.adjust.methods,
                                  selected = "fdr"),
                      
                      actionButton("submit3", label = "Run"),
                      footer = "DO NOT CHANGE, JUST RUN"
                      
               ),   
               
               
             # filter DEG
             shinydashboard::box(
               
               sliderInput("input_LFC2",
                           label = "Filter by logFoldChange",
                           min = 0,
                           max = 4,
                           value = 1,
                           step = 0.5
               ),
               numericInput("input_pvalue",
                            label = "Filter by  p adj value",
                            min = 0,
                            max =  1,
                            value = 0.05,
                            step = 0.01
               ),
               
               actionButton("submit4", label = "Run")
               
             )
            )
  ),
# tabItems: DEG exploration -----------------------------------------------

  tabItem( tabName = "Exp",
           fluidRow(
             # selection
             shinydashboard::box(
               div(style='overflow-x: scroll', DT::dataTableOutput("dataset1")),
               br(),
               downloadLink("download_dataset1","Download csv"),
               title = "Differential expression genes",
               width = 12
               
             )),
             
           fluidRow(
             # volcano plot
             shinydashboard::box(
                          plotOutput("volcano" ),
                          downloadLink("download_volcano","Volcano plot download"),
                          title = "Volcano Plot" 
                        
                        
               ),
             # dot plot of selected gene
             shinydashboard::box(
               plotOutput("genedotplot" ),
               downloadLink("download_genedotplot","gene dot plot download"),
               title = "gene expression dot plot" 
             )
               
             ),
             br(),
             tags$p("If you use DESeq2 in published research, please cite:"),
             tags$p("Love, M.I., Huber, W., Anders, S. (2014) Moderated estimation of fold change and dispersion for RNA-seq data with DESeq2. Genome Biology, 15:550")
             
    ),

# tabItem: Enrichment Analysis --------------------------------------------
    tabItem( tabName = "Enrichment",
             # GO / KEGG enrichment analysis
             fluidRow(
               shinydashboard::box(width = 4,
                      tags$p("GO and KEGG enrichment analysis"),
                      selectInput("input_ont",
                                  label = "Ontology",
                                  choices = c("BP","MF","CC","KEGG"),
                                  selected = "BP"
                      ),
                      selectInput("input_gene",
                                  label = "enriched gene",
                                  choices = c("up","down","all"),
                                  selected = "all"
                      ),
                      
                      actionButton("submit5", label = "Run")
                      
               )),
             fluidRow(
               shinydashboard::box(width = 12,
               title = "GO and KEGG enrichment analysis",
                      fluidRow( plotOutput("dotplot" )),
                      downloadLink("download_go_kegg","Download csv"),
                      br(),
                      tags$p("clusterProfiler v3.10.1  For help: https://guangchuangyu.github.io/software/clusterProfiler"),
                      tags$p("If you use clusterProfiler in published research, please cite:"),
                      tags$p("Guangchuang Yu, Li-Gen Wang, Yanyan Han, Qing-Yu He. clusterProfiler: an R package for comparing biological themes among gene clusters. OMICS: A Journal of Integrative Biology. 2012, 16(5):284-287.")
                      
             ))
    ),

# tabItem: GSEA -----------------------------------------------------------
    tabItem( tabName = "GSEA",
             fluidRow(
             shinydashboard::box(
                    tags$p("GO and KEGG GSEA analysis"),
                    selectInput("input_ont2",
                                label = "Ontology",
                                choices = c("BP","CC","MF","KEGG"),
                                selected = "fdr"),
                    selectInput("input_rank",
                                label = "rank type",
                                choices = c("padj","log2FoldChange"),
                                selected = "log2FoldChange"),
                    actionButton("submit6", label = "Run"),
                    width = 4
             ),
             
             shinydashboard::box(
               plotOutput("gseaplot" ),
               title = "GSEA plot",width = 8
             )
             ),
             fluidRow(
               shinydashboard::box(
                 div(style='overflow-x: scroll',DT::dataTableOutput("gsea")),
                 br(),
                 downloadLink("download_gsea","Download csv"),
                 title = "GSEA enriched terms",
                 width = 12
               )

             )
      
    )
 )
  
)


# UI ----------------------------------------------------------------------

ui <- dashboardPage(
  title = "Arabidopsis RNA-seq Analysis Platform",
  header  = dashboardHeader(title = "RNA-seq downstream Analysis"),
  sidebar = dashboardsider,
  body    = dashboardbody
  
)


# Server ------------------------------------------------------------------

server <- function(input, output, session){


# globa value setting -----------------------------------------------------
  global_value <- reactiveValues(
    output_mat = NULL,
    samples = NULL,
    # DE analysis
    control = NULL,  # control group
    case = NULL, # case group
    dds = NULL,
    lfc = NULL,
    methods = NULL,
    # result filter
    lfc2 = NULL,
    pvalue = NULL,
    output_res = NULL,
    symbol = symbol,
    # GO and KEGG
    ont = NULL,
    gene_type = NULL,
    ont2 = NULL,
    rank_type = NULL

  )

# Read the expression matrix ----------------------------------------------
  # get the samples name for selections
  observeEvent({
    input$upload_mat
    
  },{
    global_value$output_mat <- read.table(input$upload_mat$datapath,
                                                 sep = "\t",
                                                 row.names = 1,
                                                 header= TRUE)
    global_value$samples <- colnames(global_value$output_mat)
    
  })
  

# output the read count expression matrix ---------------------------------
  output$dataset2 <- DT::renderDT({
    
    validate(
      need( ! is.null(global_value$output_mat), "Submit data first" )
    )
    
    output_df <- global_value$output_mat
    output_df
    
  },
  server = TRUE,
  filter = "top",
  options = list(
    dom = 'Bfrtip', buttons = I('colvis')
  ),
  escape = FALSE  
  
  )
  

# Update the selections ---------------------------------------------------
  observe({
    updateSelectizeInput(session,
                         inputId = "input_control",
                         choices = global_value$samples,
                         server = TRUE
    )
    updateSelectizeInput(session,
                         inputId = "input_case",
                         choices = global_value$samples,
                         server = TRUE
    )
  })
  

# Build DESeqDataSet object ---------------------------------------------
# From matrix, control and case group
  source("scripts/BuildDdsFromMatrix.R", local = TRUE)
  observeEvent(input$submit2,{
    
    global_value$control = input$input_control
    global_value$case =  input$input_case
    
    # build DESeqDataSet 
    global_value$dds = BuildDdsFromMatrix(
      global_value$output_mat,
      global_value$control,
      global_value$case
   
    )
  })
  

# PCA plot ----------------------------------------------------------------
  source("scripts/PCA_plot.R", local = TRUE)
  output$pcaplot <- renderPlot({
    validate(
      need( ! is.null(global_value$control ), "Select the control samples" ),
      need( ! is.null(global_value$case ), "Select the case  samples" )
    )
    p <- PCA_plot(global_value$dds)
    p
  })
  

# DEG analysis ----------------------------------------
  source("scripts/DGE_analysis.R", local = TRUE)
  observeEvent(input$submit3,{
    
    global_value$lfc = input$input_LFC
    global_value$methods =  input$input_methods
    
    # build DESeqDataSet 
    DGE = DGE_analysis(
      global_value$dds,
      global_value$lfc,
      global_value$methods
      
    )
    
    global_value$dds = DGE[[1]]
    global_value$res = DGE[[2]]      
    
  })
  

# Filter the results ------------------------------------------------------
  source("scripts/DE_results_filter.R", local = TRUE)
  observeEvent(input$submit4,{
    
    global_value$lfc2   = input$input_LFC2
    global_value$pvalue =  input$input_pvalue
    
    # build DESeqDataSet 
    global_value$output_res = DE_result_filter(
      global_value$res,
      global_value$dds,
      global_value$symbol,
      global_value$lfc2,
      global_value$pvalue
      
    )
  })

# Download Filter results -------------------------------------------------
  output$download_dataset1 <- downloadHandler(
    
    filename = "DEG.csv",
    content  = function(file){
      write.csv(global_value$output_res, file, row.names = FALSE)
    }
    
  )

    

# DT: filter the results with LFC and pvalue ------------------------------
  output$dataset1 <- DT::renderDT({
    
    validate(
      need( ! is.null(global_value$res), "Run Differential gene analysis first" ),
      need( ! is.null(global_value$lfc2), "Select LogFoldChange" ),
      need( ! is.null(global_value$pvalue), "Select p value" )
    )
    
    global_value$output_res
    
  },
  server = TRUE,
  selection = 'single'
  )
  

# Volcano plot ------------------------------------------------------------
  
  output$volcano <- renderPlot({
    
    validate( 
      need( ! is.null(global_value$res), "Run Differential gene analysis first" )
      )
    
    df <- as.data.frame(global_value$res)

    #print(geneid)
    p <- volcano_plot(df)
    if ( length(input$dataset1_rows_selected) ){
      geneid <- global_value$output_res[input$dataset1_rows_selected, 
                                        c('geneID')]
      p <- volcano_plot(df, geneid)
    }
    p
    
  })


# Gene Expression Dot Plot ------------------------------------------------
  output$genedotplot <- renderPlot({
    
    validate(
      need( length(input$dataset1_rows_selected) == 1, "select a gene")
    )
    
    geneid <- global_value$output_res[input$dataset1_rows_selected, 
                                      c('geneID')]
    p <- gene_dot_plot(global_value$dds, geneid)
    p
    
  })

  
  
# Enrichment analysis -----------------------------------------------------
  source("scripts/Enrichment_analysis.R", local = TRUE)
  # GO_enrich_analysis
  observeEvent(input$submit5,{
    
    global_value$ont       = input$input_ont
    global_value$gene_type =  input$input_gene
    
    global_value$eout = enrich_analysis(
      global_value$output_res,
      global_value$gene_type,
      global_value$ont
      
    )
  })
  
  output$dotplot <- renderPlot({
    
    validate(
      need( ! is.null(global_value$eout ), "Run enrichment analysis first")
    )
    enrich_plot(global_value$eout)
    
  })

# Download KEGG and GO ----------------------------------------------------
  output$download_go_kegg <- downloadHandler(
    
    filename = "enrichment_result.csv",
    content = function(file){
      df <- as.data.frame(global_value$eout)
      write.csv(df, file, row.names = FALSE)
    }
    
  )

  
# GSEA analysis ---------------------------------------------------------
observeEvent(input$submit6,{
    
    global_value$ont2      = input$input_ont2
    global_value$rank_type = input$input_rank
    
    global_value$gseaout = GSEA_analysis(
      global_value$res,
      global_value$rank_type,
      global_value$ont2
      
    )
  })
  
  output$gsea <- DT::renderDT({
    
    validate(
      need( ! is.null(global_value$gseaout ), "Run GSEA analysis first")
    )
    as.data.frame(global_value$gseaout)
    
  }, selection = 'single'
  
  )

# GSEA plot ---------------------------------------------------------------
  output$gseaplot <- renderPlot({
    
    validate(
      need( length(input$gsea_rows_selected) > 0, "Select a term")
    )
    
    s <- input$gsea_rows_selected
    
    p <- GSEA_plot(global_value$gseaout, s)
    p
  })
  
# GSEA output -------------------------------------------------------------
  output$download_gsea <- downloadHandler(
    
    filename = "GSEA_enrcihment_result.csv",
    content = function(file){
      df <- as.data.frame(global_value$gseaout)
      write.csv(df, file, row.names = FALSE)
    }
    
  )
  
    
}






# Run ---------------------------------------------------------------------

shinyApp(ui = ui, server = server)