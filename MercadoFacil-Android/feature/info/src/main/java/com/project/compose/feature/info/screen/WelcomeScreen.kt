package com.project.compose.feature.info.screen

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.project.compose.core.common.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WelcomeScreen(
    onNavigateToLogin: () -> Unit,
    onNavigateToRegister: () -> Unit,
    onNavigateToForgotPassword: () -> Unit
) {
    var showLegalDoc by remember { mutableStateOf<String?>(null) }
    var sheetTitle by remember { mutableStateOf("") }
    var sheetContent by remember { mutableStateOf("") }
    
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val primaryColor = Color(0xFF007AFF) // Ajuste para a cor primária do seu app
    val backgroundColor = Color(0xFFFFFFFF)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(backgroundColor)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Placeholder para a imagem splash_top
            // Substitua R.drawable.splash_top pela sua imagem
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .background(Color.LightGray),
                contentAlignment = Alignment.Center
            ) {
                Text("Logo / Splash Top", color = Color.White)
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 32.dp, vertical = 40.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Button(
                    onClick = onNavigateToLogin,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = primaryColor),
                    shape = RoundedCornerShape(30.dp)
                ) {
                    Text("Iniciar", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.White)
                }

                OutlinedButton(
                    onClick = onNavigateToRegister,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = primaryColor),
                    border = androidx.compose.foundation.BorderStroke(2.dp, primaryColor),
                    shape = RoundedCornerShape(30.dp)
                ) {
                    Text("Cadastro", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = primaryColor)
                }

                Text(
                    text = "Esqueceu a senha?",
                    modifier = Modifier
                        .clickable { onNavigateToForgotPassword() }
                        .padding(top = 8.dp),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = primaryColor
                )

                // Links Legais
                Row(
                    modifier = Modifier.padding(top = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Termos de Uso",
                        fontSize = 12.sp,
                        color = Color.Gray,
                        modifier = Modifier.clickable {
                            sheetTitle = "Termos de Uso"
                            sheetContent = "TERMOS E CONDIÇÕES DE USO DO APLICATIVO ACHOU\n\n1. ACEITAÇÃO..."
                            showLegalDoc = "termos"
                        }
                    )
                    Text("•", fontSize = 12.sp, color = Color.Gray)
                    Text(
                        text = "Privacidade",
                        fontSize = 12.sp,
                        color = Color.Gray,
                        modifier = Modifier.clickable {
                            sheetTitle = "Política de Privacidade"
                            sheetContent = "POLÍTICA DE PRIVACIDADE E PROTEÇÃO DE DADOS..."
                            showLegalDoc = "privacidade"
                        }
                    )
                    Text("•", fontSize = 12.sp, color = Color.Gray)
                    Text(
                        text = "Segurança",
                        fontSize = 12.sp,
                        color = Color.Gray,
                        modifier = Modifier.clickable {
                            sheetTitle = "Segurança de Dados"
                            sheetContent = "DIRETRIZES DE SEGURANÇA DE DADOS..."
                            showLegalDoc = "seguranca"
                        }
                    )
                }
            }

            // Placeholder para a imagem splash_bottom
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
                    .background(Color.LightGray),
                contentAlignment = Alignment.Center
            ) {
                Text("Splash Bottom", color = Color.White)
            }
        }
    }

    if (showLegalDoc != null) {
        ModalBottomSheet(
            onDismissRequest = { showLegalDoc = null },
            sheetState = sheetState
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp)
            ) {
                Text(
                    text = sheetTitle,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
                // Usando Scroll no caso de texto muito grande
                androidx.compose.foundation.rememberScrollState().let { scrollState ->
                    Column(modifier = Modifier.verticalScroll(scrollState)) {
                        Text(
                            text = sheetContent,
                            fontSize = 14.sp,
                            color = Color.DarkGray
                        )
                    }
                }
            }
        }
    }
}
