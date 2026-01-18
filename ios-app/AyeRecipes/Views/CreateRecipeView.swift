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

struct IngredientItem: Identifiable, Hashable {
    let id: UUID
    var name: String
    var quantity: String
    var unit: String
    
    init(name: String, quantity: String, unit: String) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }
}

struct CreateRecipeView: View {
    @EnvironmentObject var recipeService: RecipeService
    
    // NUEVO: Enum para controlar qué campo tiene el foco (teclado activo)
    enum Field: Hashable {
        case ingredient
        case quantity
        case step
    }
    
    // NUEVO: Variable de estado para el foco
    @FocusState private var focusedField: Field?
    
    @State private var title = ""
    @State private var description = ""
    
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity = ""
    @State private var newIngredientUnit = "g"
    @State private var ingredients: [IngredientItem] = []
    
    let units = ["g", "kg", "ml", "L", "cups", "tbsp", "tsp"]
    
    @State private var newStep = ""
    @State private var steps: [RecipeStepItem] = []
    
    @State private var isSaving = false
    @State private var showResultOverlay = false
    @State private var saveSuccess: Bool? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Information")) {
                        TextField("Recipe Title", text: $title)
                        TextField("Short description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    // MARK: - Sección Ingredientes
                    Section(header: Text("Ingredients")) {
                        HStack {
                            TextField("Ingredient", text: $newIngredientName)
                                .focused($focusedField, equals: .ingredient)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .quantity
                                }
                            
                            Divider()
                            
                            TextField("Qty", text: $newIngredientQuantity)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .quantity)
                                .keyboardType(.decimalPad)
                                .frame(width: 50)
                                .submitLabel(.done)
                                .onSubmit {
                                    addIngredient()
                                    focusedField = .ingredient
                                }
                            
                            Picker("", selection: $newIngredientUnit) {
                                ForEach(units, id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(maxWidth: 66)
                            
                            Button(action: addIngredient) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newIngredientName.isEmpty)
                        }
                        
                        ForEach(ingredients) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("\(item.quantity) \(item.unit)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteIngredient)
                        .onMove(perform: moveIngredient) // NUEVO: Permite reordenar
                    }
                    
                    // MARK: - Sección Pasos
                    Section(header: Text("Steps")) {
                        HStack {
                            TextField("Add step", text: $newStep)
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
                            ZStack {
                                Text("Save Recipe")
                                    .frame(maxWidth: .infinity)
                                    .opacity(isSaving ? 0 : 1)
                                
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(saveSuccess == nil ? nil : (saveSuccess == true ? .green : .red))
                        .disabled(title.isEmpty || isSaving)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle("Create Recipe")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
                
                // Overlay de resultado (Éxito o Error)
                if showResultOverlay {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    VStack(spacing: 16) {
                        Image(systemName: (saveSuccess == true) ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor((saveSuccess == true) ? .green : .red)
                        
                        Text((saveSuccess == true) ? "Saved!" : "Error")
                            .font(.headline)
                        
                        Text((saveSuccess == true) ? "Recipe created successfully" : "Could not save recipe")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .frame(width: 200)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Funciones
    
    func addIngredient() {
        guard !newIngredientName.isEmpty else { return }
        let quantity = newIngredientQuantity.isEmpty ? "1" : newIngredientQuantity
        ingredients.append(IngredientItem(name: newIngredientName, quantity: quantity, unit: newIngredientUnit))
        newIngredientName = ""
        newIngredientQuantity = ""
        newIngredientUnit = "g"
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
        saveSuccess = nil
        
        Task {
            let success = await recipeService.createRecipe(
                title: title,
                description: description,
                ingredients: ingredients.map { "\($0.quantity) \($0.unit) \($0.name)" },
                steps: steps.map { $0.text }
            )
            
            isSaving = false
            saveSuccess = success
            
            if success {
                title = ""
                description = ""
                ingredients = []
                steps = []
                newIngredientName = ""
                newIngredientQuantity = ""
            }
            
            withAnimation {
                showResultOverlay = true
            }
            
            // Ocultar el mensaje después de 2 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showResultOverlay = false
                }
                // Resetear el color del botón poco después
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    saveSuccess = nil
                }
            }
        }
    }
}

#Preview {
    CreateRecipeView()
        .environmentObject(RecipeService())
}
