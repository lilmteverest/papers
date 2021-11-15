# Code by Lisa Everest

using JuMP
using Gurobi
using Pkg
using DataFrames
using CSV

data = CSV.read("coursedata.csv", header = true)

# Adjustable constants for Constraints
# Baseline analysis
maxClasses = 4
maxCredits = 60
maxWorkload = 64

# Sensitivity analysis 1
# maxClasses = 5
# maxCredits = 60
# maxWorkload = 64

# Sensitivity analysis 2
# maxClasses = 6
# maxCredits = 60
# maxWorkload = 64

# Sensitivity analysis 3
# maxClasses = 3
# maxCredits = 60
# maxWorkload = 64

# Sensitivity analysis 4
# maxClasses = 5
# maxCredits = 72
# maxWorkload = 64

# Sensitivity analysis 5
# maxClasses = 5
# maxCredits = 64
# maxWorkload = 72

# Sensitivity analysis 6
# maxClasses = 5
# maxCredits = 72
# maxWorkload = 72

# Sensitivity analysis 7
# maxClasses = 6
# maxCredits = 72
# maxWorkload = 72

# Sensitivity analysis 8
# maxClasses = 7
# maxCredits = 72
# maxWorkload = 72

# Unadjustable constants for constraints
maxCreditsSemester1 = 54
maxCreditsSemester2 = 60

numClasses = size(data)[1]
numSemesters = 8

# Arrays obtained from data
classes = data[1]
credits = data[2]
semesterOffered = data[3]
prereqsAll = data[4]
workload = data[5]
rating = data[6]
isGIR = data[7]
isCore = data[8]
electiveGroup = data[9]
electiveType = data[10]

# Make dictionary mapping class number to its index in the DataFrame
# Also make list of HASS classes that are 15-2 electives
classIndexDict = Dict{Float64, Int}()
hassBusinessElectives = []
hassClasses = []
for i = 1:numClasses
    classIndexDict[classes[i]] = i
    if floor(classes[i]) == 14
        push!(hassBusinessElectives,i)
    end
    if isGIR[i] == 2
        push!(hassClasses,i)
    end
end

# Make dictionary,p mapping index of class to array of the indices of its prerequisites
prereqsAllDict = Dict{Int,Array{Int}}()
electiveGroupsDict = Dict{Array{Float64},Int}()
for i = 1:numClasses
    if  prereqsAll[i] == "x"
        prereqsAllDict[i] = []
    else
        prereqs = map(x->parse(Float64,x),split(prereqsAll[i], ", "))
        prereqIndices = map(x->classIndexDict[x], prereqs)
        prereqsAllDict[i] = prereqIndices
    end
    if electiveGroup[i] != "x"
        electives = map(x->parse(Float64,x),split(electiveGroup[i], ", "))
        electiveGroupsDict[electives] = electiveType[i]
    end
end
for group1 in keys(electiveGroupsDict)
    if electiveGroupsDict[group1] == 2
        for group2 in keys(electiveGroupsDict)
            if electiveGroupsDict[group2] == 3
                merged = []
                append!(merged, group1)
                append!(merged,group2)
                electiveGroupsDict[merged] = 4
                break
            end
        end
    end
end

# Initialize model
businessAnalytics = Model(with_optimizer(Gurobi.Optimizer))

# Add variables to model, where
# x[i,j] = 1 if course classes[i] is taken in semester j
@variable(businessAnalytics, x[1:numClasses,1:numSemesters], Bin)
# y[i] = 1 if any class is taken in semester i
@variable(businessAnalytics, y[1:numSemesters], Bin)

@objective(businessAnalytics, Min, sum(y[i] for i in 1:numSemesters))

# Constraint on y[i], for semesters that are "used" for maxClasses
for semester in 1:numSemesters
    @constraint(businessAnalytics, y[semester] * numSemesters >= sum(x[i,j] for i = 1:numClasses for j = semester))
end

# Constraint on number of classes taken per semester
for semester in 1:numSemesters
    @constraint(businessAnalytics, sum(x[i,j] for i = 1:numClasses for j = semester) <= maxClasses)
end

# Constraint on credit limit in non-freshman year
for semester in 3:numSemesters
    @constraint(businessAnalytics, sum(x[i,j]*credits[i] for i = 1:numClasses for j = semester) <= maxCredits)
end

# Constraint on credit limit in freshman year
@constraint(businessAnalytics, sum(x[i,j] for i = 1:numClasses for j = 1) <= maxCreditsSemester1)
@constraint(businessAnalytics, sum(x[i,j] for i = 1:numClasses for j = 2) <= maxCreditsSemester2)

# Constraint on workload limit
for semester in 1:numSemesters
    @constraint(businessAnalytics, sum(x[i,j]*workload[i] for i = 1:numClasses for j = semester) <= maxWorkload)
end

# Constraint on HASS, non-bio GIR classes
@constraint(businessAnalytics, sum(x[i,j] for i in hassClasses for j = 1:numSemesters) +
        sum(x[i,j] for i in hassBusinessElectives for j = 1:numSemesters)  == 8 )

# Constraint on GIR, HASS, core 15-2 requirements
for class in 1:numClasses
    if isGIR[class] == 1 # Constraint on non-HASS, non-bio GIR classes
        @constraint(businessAnalytics, sum(x[i,j] for i = class for j = 1:2) == 1)
        @constraint(businessAnalytics, sum(x[i,j] for i = class for j = 3:numSemesters) == 0)
    elseif isGIR[class] == 3 # Constraint on non-HASS, bio GIR classes
        @constraint(businessAnalytics, sum(x[i,j] for i = class for j = 3:numSemesters) == 0)
        # @constraint(businessAnalytics, sum(x[i,j] for i = class for j = 1:numSemesters) <= 1)
    elseif isCore[class] == 1 # Constraint on core 15-2 requirements
        @constraint(businessAnalytics, sum(x[i,j] for i = class for j = 1:numSemesters) == 1)
    end
end

# Constraint on elective 15-2 or elective GIR requirements
for group in keys(electiveGroupsDict)
    indicesOfClassesInGroup = []
    for i in 1:numClasses
        if in(classes[i], group)
            push!(indicesOfClassesInGroup, i)
        end
    end
    if electiveGroupsDict[group] == 1
        @constraint(businessAnalytics, sum(x[i,j] for i in indicesOfClassesInGroup for j = 1:numSemesters) == 1)
    elseif electiveGroupsDict[group] == 2
        @constraint(businessAnalytics, 3 <= sum(x[i,j] for i in indicesOfClassesInGroup for j = 1:numSemesters) <= 5)
    elseif electiveGroupsDict[group] == 3
        @constraint(businessAnalytics, sum(x[i,j] for i in indicesOfClassesInGroup for j = 1:numSemesters) <= 2)
    elseif electiveGroupsDict[group] == 4
        @constraint(businessAnalytics, sum(x[i,j] for i in indicesOfClassesInGroup for j = 1:numSemesters) == 5)
    end
end

# Constraint to ensure each class is taken at most once
for class in 1:numClasses
    @constraint(businessAnalytics, sum(x[i,j] for i = class for j = 1:numSemesters) <= 1)
end

# Constraint to ensure prereqs are satisfied for all classes with prereqs
for class in 1:numClasses
    for sem in 1:numSemesters
        @constraint(businessAnalytics, length(prereqsAllDict[class])*x[class,sem] <=
                                       sum(x[i,j] for i in prereqsAllDict[class] for j = 1:(sem-1)))
    end
end

# Constraint on semester offered
for class in 1:numClasses
    if semesterOffered[class] == 1 # offered only in fall (semesters 1, 3, 5, 7)
        for springSemester in [2,4,6,8]
            @constraint(businessAnalytics, x[class,springSemester] == 0)
        end
    elseif semesterOffered[class] == 2 #offered only in spring (semesters 2,4,6, 7)
        for fallSemester in [1,3,5,7]
            @constraint(businessAnalytics, x[class,fallSemester] == 0)
        end
    end
end

# Solve optimization model
@time optimize!(businessAnalytics)

# Print out solution
optimalClasses = DataFrame(map(x->Int(x), value.(x)))
optimalClasses.Course = classes
permutecols!(optimalClasses, [:Course, :x1, :x2, :x3, :x4, :x5, :x6, :x7, :x8])
println(optimalClasses)
println(string("Number of semesters = ", JuMP.objective_value(businessAnalytics)))
println(string("Total ratings = ", sum(JuMP.value(x[i,j])*rating[i] for i in 1:numClasses for j in 1:numSemesters)))

# Baseline analysis
# CSV.write("optimizeSemesters0.csv", optimalClasses)
# Semesters = 7.0
# Ratings = 145.28333333299997

# Sensitivity analysis 1
# CSV.write("optimizeSemesters1.csv", optimalClasses)
# Semesters = 5.0
# Ratings = 145.68333333299998

# Sensitivity analysis 2
# CSV.write("optimizeSemesters2.csv", optimalClasses)
# Semesters = 5.0
# Ratings = 145.95

# Sensitivity analysis 3
# CSV.write("optimizeSemesters3.csv", optimalClasses)
# Can't graduate!!!

# Sensitivity analysis 4
# CSV.write("optimizeSemesters4.csv", optimalClasses)
# Semesters = 5.0
# Ratings = 145.68333333299998

# Sensitivity analysis 5
# CSV.write("optimizeSemesters5.csv", optimalClasses)
# Semesters = 5.0
# Ratings = 145.68333333299998

# Sensitivity analysis 6
# CSV.write("optimizeSemesters6.csv", optimalClasses)
# Semesters = 5.0
# Ratings = 145.68333333299998

# Sensitivity analysis 7
# CSV.write("optimizeSemesters7.csv", optimalClasses)
# Semesters = 5.0
# Ratings = 144.98333333399998

# Sensitivity analysis 8
# CSV.write("optimizeSemesters8.csv", optimalClasses)
# Semesters = 4.0
# Ratings = 156.16666666699996
