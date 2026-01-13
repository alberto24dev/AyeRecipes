//
//  CreateRecipeView.swift
//  AyeRecipes
//
//  Created by Jose Alberto Montero Martinez on 1/12/26.
//

import SwiftUI

struct RecipeStepItem: Identifiable, Hashable, Codable {
    let id: UUID
    var text: String
    
    init(text: String) {
        self.id = UUID()
        self.text = text
    }
}

struct CreateRecipeView: View {
    @EnvironmentObject var recipeService: RecipeService
    
    // NUEVO: Enum para controlar qué campo tiene el foco (teclado activo)
    enum Field: Hashable {
        case ingredient
        case step
    }
    
    // NUEVO: Variable de estado para el foco
    @FocusState private var focusedField: Field?
    
    @State private var title = ""
    @State private var description = ""
    
    @State private var newIngredient = ""
    @State private var ingredients: [String] = []
    
    @State private var newStep = ""
    @State private var steps: [RecipeStepItem] = []
    
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información")) {
                    TextField("Título de la receta", text: $title)
                    TextField("Descripción breve", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // MARK: - Sección Ingredientes
                Section(header: Text("Ingredientes")) {
                    HStack {
                        TextField("Agregar ingrediente", text: $newIngredient)
                            .focused($focusedField, equals: .ingredient) // Vincula el foco
                            .submitLabel(.next) // Cambia visualmente el botón a "Siguiente" o "Enter"
                            .onSubmit {
                                addIngredient()
                                // NUEVO: Mantiene el foco aquí tras dar Enter
                                focusedField = .ingredient
                            }
                        
                        Button(action: addIngredient) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newIngredient.isEmpty)
                    }
                    
                    ForEach(ingredients, id: \.self) { ingredient in
                        Text(ingredient)
                    }
                    .onDelete(perform: deleteIngredient)
                    .onMove(perform: moveIngredient) // NUEVO: Permite reordenar
                }
                
                // MARK: - Sección Pasos
                Section(header: Text("Pasos")) {
                    HStack {
                        TextField("Agregar paso", text: $newStep)
                            .focused($focusedField, equals: .step) // Vincula el foco
                            .submitLabel(.next)
                            .onSubmit {
                                addStep()
                                // NUEVO: Mantiene el foco aquí tras dar Enter
                                focusedField = .step
                            }
                        
                        Button(action: addStep) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newStep.isEmpty)
                    }
                    
                    ForEach(steps) { step in
                        HStack(alignment: .top) {
                            Text("\(getIndex(for: step) + 1).")
                                .bold()
                                .foregroundStyle(.secondary)
                            Text(step.text)
                        }
                    }
                    .onDelete(perform: deleteStep)
                    .onMove(perform: moveStep) // Ya existente
                }
                
                Section {
                    Button(action: saveRecipe) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Guardar Receta")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Crear Receta")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .alert("Estado", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Funciones
    
    func addIngredient() {
        guard !newIngredient.isEmpty else { return }
        ingredients.append(newIngredient)
        newIngredient = ""
        // No ponemos 'focusedField = nil' para que el teclado siga abierto
    }
    
    func deleteIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
    
    // NUEVO: Función para mover ingredientes
    func moveIngredient(from source: IndexSet, to destination: Int) {
        ingredients.move(fromOffsets: source, toOffset: destination)
    }
    
    func addStep() {
        guard !newStep.isEmpty else { return }
        steps.append(RecipeStepItem(text: newStep))
        newStep = ""
    }
    
    func deleteStep(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
    }
    
    func moveStep(from source: IndexSet, to destination: Int) {
        steps.move(fromOffsets: source, toOffset: destination)
    }
    
    func getIndex(for step: RecipeStepItem) -> Int {
        return steps.firstIndex(where: { $0.id == step.id }) ?? 0
    }
    
    func saveRecipe() {
        // Al guardar, sí queremos esconder el teclado
        focusedField = nil
        
        isSaving = true
        Task {
            let success = await recipeService.createRecipe(
                title: title,
                description: description,
                ingredients: ingredients,
                steps: steps.map { $0.text }
            )
            
            isSaving = false
            if success {
                alertMessage = "Receta guardada exitosamente"
                title = ""
                description = ""
                ingredients = []
                steps = []
            } else {
                alertMessage = "Error al guardar la receta"
            }
            showAlert = true
        }
    }
}

#Preview {
    CreateRecipeView()
        .environmentObject(RecipeService())
}
