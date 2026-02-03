import SwiftUI

/// 篩選條件 Sheet
struct FilterSheet: View {
    @ObservedObject var viewModel: RandomPickerViewModel
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Pro 功能區
                    proFeaturesSection
                    
                    Divider()
                    
                    // 品牌篩選
                    filterSection(title: "品牌", icon: "building.2") {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.allBrands) { brand in
                                FilterChip(
                                    title: brand.name,
                                    isSelected: viewModel.criteria.selectedBrands.contains(brand.id)
                                ) {
                                    viewModel.toggleBrand(brand.id)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 分類篩選
                    filterSection(title: "飲品分類", icon: "square.grid.2x2") {
                        FlowLayout(spacing: 8) {
                            ForEach(DrinkCategory.allCases) { category in
                                FilterChip(
                                    title: category.rawValue,
                                    isSelected: viewModel.criteria.selectedCategories.contains(category)
                                ) {
                                    viewModel.toggleCategory(category)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 甜度篩選
                    filterSection(title: "甜度", icon: "drop") {
                        FlowLayout(spacing: 8) {
                            ForEach(SugarLevel.allCases) { level in
                                FilterChip(
                                    title: level.rawValue,
                                    isSelected: viewModel.criteria.selectedSugarLevels.contains(level)
                                ) {
                                    viewModel.toggleSugarLevel(level)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 熱量區間
                    filterSection(title: "熱量區間", icon: "flame") {
                        HStack(spacing: 12) {
                            ForEach(CalorieRange.allCases) { range in
                                calorieRangeButton(range)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 咖啡因篩選
                    filterSection(title: "咖啡因", icon: "cup.and.saucer") {
                        HStack(spacing: 12) {
                            caffeineButton(title: "都可以", value: nil)
                            caffeineButton(title: "含咖啡因", value: true)
                            caffeineButton(title: "無咖啡因", value: false)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("篩選條件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("重置") {
                        viewModel.resetFilters()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(userManager)
            }
        }
    }
    
    // MARK: - Pro Features Section
    
    private var proFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("Pro 功能")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if userManager.isProUser {
                    Text("已解鎖")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
            }
            
            // 優先推薦
            proFeatureToggle(
                title: "智慧推薦",
                description: "優先顯示你評分 ≥ 4 星的飲料",
                icon: "sparkles",
                isOn: Binding(
                    get: { viewModel.criteria.smartPriority },
                    set: { newValue in
                        if userManager.isProUser {
                            viewModel.setSmartPriority(newValue)
                        } else if newValue {
                            showPaywall = true
                        }
                    }
                )
            )
            
            // 避雷模式
            proFeatureToggle(
                title: "避雷模式",
                description: "自動排除評分 ≤ 2 星的飲料",
                icon: "hand.thumbsdown.fill",
                isOn: Binding(
                    get: { viewModel.criteria.antiThunder },
                    set: { newValue in
                        if userManager.isProUser {
                            viewModel.setAntiThunder(newValue)
                        } else if newValue {
                            showPaywall = true
                        }
                    }
                )
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func proFeatureToggle(title: String, description: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.teaBrown)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !userManager.isProUser {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.teaBrown)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Views
    
    private func filterSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.teaBrown)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            content()
        }
    }
    
    private func calorieRangeButton(_ range: CalorieRange) -> some View {
        let isSelected = viewModel.criteria.calorieRange == range
        
        return Button {
            viewModel.setCalorieRange(isSelected ? nil : range)
        } label: {
            VStack(spacing: 4) {
                Text(range.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(range.description)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.teaBrown : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
    
    private func caffeineButton(title: String, value: Bool?) -> some View {
        let isSelected = viewModel.criteria.hasCaffeine == value
        
        return Button {
            viewModel.setCaffeineFilter(value)
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.teaBrown : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
    
    private var resultCountView: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Text("符合條件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Text("\(viewModel.filteredCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.teaBrown)
                    Text("款飲料")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

#Preview {
    FilterSheet(viewModel: RandomPickerViewModel())
}
